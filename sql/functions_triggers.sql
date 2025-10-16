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

-- Trigger para verifica conclusao de aulas e do curso
CREATE TRIGGER trg_progresso_aula_conclusao
BEFORE INSERT OR UPDATE ON Progresso_Aulas -- Dispara ANTES de um INSERT ou UPDATE ser salvo
FOR EACH ROW -- Para cada linha individualmente
EXECUTE FUNCTION fn_verificar_conclusao_aula_e_curso(); -- Executa a função que criamos