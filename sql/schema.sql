-- Criando tipos de seleção especificos
CREATE TYPE NIVEL_STATUS AS ENUM (
    'Iniciante', 
    'Intermediário', 
    'Avançado'
);

CREATE TYPE TIPO_AULA AS ENUM (
    'Vídeo',
    'Texto',
    'Quiz'
);

CREATE TYPE MATRICULA_STATUS AS ENUM (
    'Ativa',
    'Concluído',
    'Cancelada'
);

--------------------------
--DEFINIÇÃO DOS TRIGGERS--
--------------------------

-- Definindo função para atualizar a data de modificação ao atualizar alguma tabela que contenha esse campo
CREATE OR REPLACE FUNCTION fn_atualizar_data_modificacao()
RETURNS TRIGGER AS $$
BEGIN
   NEW.data_modificacao = NOW(); -- Aqui define uma variavel para que ela atualize com o tempo atual
   RETURN NEW; --Retorna o valor de data atual
END;
$$ LANGUAGE plpgsql; --Linguagem da função para postgresql

-- Esse trigger gigante foi feito com auxilio de IA, para que pudessemos seguir uma sequencia de atualizações a partir da conclusão de uma aula.
-- Uma aula é concluída se a quantidade de tempo assistido for igual a carga horaria dela.
-- Se todas as aulas de todos os módulos estão concluídas, isso significa que aquela matrícula concluiu um curso.
CREATE OR REPLACE FUNCTION fn_verificar_conclusao_aula_e_curso()
RETURNS TRIGGER AS $$
DECLARE --Variaveis da função
    v_duracao_total_aula INTEGER;
    v_curso_id INTEGER;
    v_total_aulas_no_curso INTEGER;
    v_aulas_concluidas_pelo_aluno INTEGER;
BEGIN
    -- =================================================================
    -- ETAPA 1: VERIFICAR E MARCAR A CONCLUSÃO DA AULA INDIVIDUAL
    -- =================================================================
    
    -- Se o progresso da aula já está como concluído, não fazemos nada para evitar reprocessamento.
    -- O 'OLD.concluida IS NOT TRUE' é importante para updates, garantindo que só agimos na transição para 'concluído'.
    IF NEW.concluida IS NOT TRUE THEN
        -- Busca a duração total da aula que está sendo atualizada.
        SELECT duracao_minutos INTO v_duracao_total_aula FROM Aulas WHERE aula_id = NEW.aula_id;

        -- Se o tempo assistido atingiu ou ultrapassou a duração total, marcamos a aula como concluída.
        IF NEW.tempo_assistido_minutos >= v_duracao_total_aula THEN
            NEW.concluida := TRUE;
            NEW.data_conclusao := NOW();
        END IF;
    END IF;

    -- =================================================================
    -- ETAPA 2: VERIFICAR A CONCLUSÃO DO CURSO (SE UMA AULA FOI CONCLUÍDA)
    -- =================================================================

    -- Esta lógica só executa se a aula FOI marcada como concluída NESTA TRANSAÇÃO.
    -- Comparamos o estado NOVO com o ANTIGO (para o caso de UPDATEs).
    IF NEW.concluida = TRUE AND (TG_OP = 'INSERT' OR OLD.concluida IS NOT TRUE) THEN
        
        -- 1. Descobrir qual é o curso desta matrícula.
        SELECT curso_id INTO v_curso_id FROM Matriculas WHERE matricula_id = NEW.matricula_id;

        -- 2. Contar o total de aulas que existem nesse curso.
        SELECT COUNT(a.aula_id)
        INTO v_total_aulas_no_curso
        FROM Aulas a
        JOIN Modulos m ON a.modulo_id = m.modulo_id
        WHERE m.curso_id = v_curso_id;

        -- 3. Contar quantas aulas o aluno já concluiu para esta matrícula.
        -- Somamos +1 na contagem se a aula atual acabou de ser concluída,
        -- pois a transação ainda não foi finalizada (commit).
        SELECT COUNT(*)
        INTO v_aulas_concluidas_pelo_aluno
        FROM Progresso_Aulas
        WHERE matricula_id = NEW.matricula_id AND concluida = TRUE;

        -- Se a aula atual foi a última que faltava, o número de concluídas será igual ao total.
        IF (v_aulas_concluidas_pelo_aluno + 1) >= v_total_aulas_no_curso THEN
            -- 4. Atualizar a matrícula como concluída.
            UPDATE Matriculas
            SET
                data_conclusao = NOW(),
                status_matricula = 'Concluído'
            WHERE matricula_id = NEW.matricula_id;
        END IF;
    END IF;

    -- Retorna a linha (potencialmente modificada) para ser inserida/atualizada.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

----------------------
--CRIAÇÃO DE TABELAS--
----------------------

-- Criação da tabela de alunos
CREATE TABLE Alunos (
    aluno_id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    sobrenome VARCHAR(100) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    data_nascimento DATE NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_modificacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criação da tabela de Instrutores
CREATE TABLE Instrutores (
    instrutor_id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    sobrenome VARCHAR(100) NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL, --Tamanho máximo para um email
    biografia TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_modificacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criação da tabela de Especialidades
CREATE TABLE Especialidades (
    especialidade_id SERIAL PRIMARY KEY,
    titulo VARCHAR(50) UNIQUE NOT NULL
);

-- Criação da tabela que irá dizer qual a especialidade dos instrutores
CREATE TABLE Especialidade_Instrutor (
    instrutor_id INTEGER NOT NULL REFERENCES Instrutores (instrutor_id),
    especialidade_id INTEGER NOT NULL REFERENCES Especialidades (especialidade_id),
    PRIMARY KEY (instrutor_id, especialidade_id) -- Não deixa repetir a especialidade no mesmo instrutor
);

-- Criação da tabela de Categorias dos cursos
CREATE TABLE Categorias (
    categoria_id SERIAL PRIMARY KEY,
    nome VARCHAR(50) UNIQUE NOT NULL,
    descricao TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criação da tabela de Cursos que serão disponibilizados
CREATE TABLE Cursos (
    curso_id SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descricao TEXT,
    categoria_id INTEGER NOT NULL REFERENCES Categorias(categoria_id) ON DELETE RESTRICT, --Não vai permitir deletar a categoria em uso
    instrutor_id INTEGER NOT NULL REFERENCES Instrutores(instrutor_id) ON DELETE RESTRICT, -- Não vai permitir deletar o instrutor em uso
    preco DECIMAL(5,2) CHECK (preco >= 49.90 AND preco <= 499.90), -- Só permite valores dentro da faixa de preço
    carga_horaria INTEGER NOT NULL CHECK(carga_horaria > 0),
    nivel NIVEL_STATUS NOT NULL, --O nível só pode ser entre os que foram criados
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_modificacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criação da tabela de Módulos
CREATE TABLE Modulos (
    modulo_id SERIAL PRIMARY KEY,
    curso_id INTEGER NOT NULL REFERENCES Cursos(curso_id) ON DELETE CASCADE, -- Caso apague algum curso, ele apaga todos os módulos desse curso.
    titulo VARCHAR(50) NOT NULL,
    ordem INTEGER NOT NULL,
    descricao TEXT,
    UNIQUE(curso_id, ordem) -- Faz com que a ordem dentro de um curso sera unica para não duplicar ordem
);

-- Criação da tabela de Aulas de cada módulo
CREATE TABLE Aulas(
    aula_id SERIAL PRIMARY KEY,
    modulo_id INTEGER NOT NULL REFERENCES Modulos(modulo_id) ON DELETE CASCADE, -- Caso apague o módulo, suas aulas são apagadas
    titulo VARCHAR(50) NOT NULL,
    ordem INTEGER NOT NULL,
    duracao_minutos INTEGER NOT NULL CHECK (duracao_minutos > 0),
    tipo TIPO_AULA NOT NULL,
    UNIQUE(modulo_id, ordem)-- Faz com que a ordem das aulas seja unica no módulo
);

-- Criação da tabela de matriculas
CREATE TABLE  Matriculas (
    matricula_id SERIAL PRIMARY KEY,
    aluno_id INTEGER NOT NULL REFERENCES Alunos(aluno_id),
    curso_id INTEGER NOT NULL REFERENCES Cursos(curso_id),
    data_matricula TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_conclusao TIMESTAMP,
    status_matricula MATRICULA_STATUS NOT NULL DEFAULT 'Ativa',
    valor_pago DECIMAL(5,2) NOT NULL,
    UNIQUE(aluno_id, curso_id) --Não permite o mesmo aluno se matricular 2x no mesmo curso
);

-- Criação da tabela de rastreio de progressão de aulas
CREATE TABLE Progresso_Aulas (
    progresso_id SERIAL PRIMARY KEY,
    matricula_id INTEGER NOT NULL REFERENCES Matriculas(matricula_id) ON DELETE CASCADE, -- Se uma matricula é excluida, exclui todo progresso associado
    aula_id INTEGER NOT NULL REFERENCES Aulas(aula_id) ON DELETE CASCADE, -- Se uma aula é excluida, o progresso dela também é
    concluida BOOLEAN DEFAULT FALSE,
    data_conclusao TIMESTAMP,
    tempo_assistido_minutos INTEGER NOT NULL CHECK (tempo_assistido_minutos > 0),
    UNIQUE(matricula_id, aula_id) --Cada aula só pode ter um registro de progresso por matricula
);

-- Criação da tabela de avaliações
CREATE TABLE Avaliacoes (
    avaliacao_id SERIAL PRIMARY KEY,
    matricula_id INTEGER NOT NULL REFERENCES Matriculas(matricula_id),
    -- Removi o curso_id pois já tem o curso_id dentro da matricula
    nota INTEGER NOT NULL CHECK(nota BETWEEN 1 AND 5),
    comentario TEXT,
    data_avalicao TIMESTAMP
);

-----------------------
--CRIAÇÃO DE TRIGGERS--
-----------------------
-- Trigger para a tabela Alunos
CREATE TRIGGER trg_alunos_data_modificacao
BEFORE UPDATE ON Alunos
FOR EACH ROW
EXECUTE FUNCTION fn_atualizar_data_modificacao();

-- Trigger para a tabela Instrutores
CREATE TRIGGER trg_instrutores_data_modificacao
BEFORE UPDATE ON Instrutores
FOR EACH ROW
EXECUTE FUNCTION fn_atualizar_data_modificacao();

-- Trigger para a tabela Cursos
CREATE TRIGGER trg_cursos_data_modificacao
BEFORE UPDATE ON Cursos
FOR EACH ROW
EXECUTE FUNCTION fn_atualizar_data_modificacao();

