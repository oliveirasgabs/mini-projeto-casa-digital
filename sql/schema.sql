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
    data_avalicao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(matricula_id)
);