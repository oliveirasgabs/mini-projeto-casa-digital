-----------------------
-- Consultas básicas --
-----------------------

-- Consulta 1: Lista de Cursos com Categoria e Instrutor
SELECT
    c.titulo AS curso_titulo,
    z.nome AS categoria_nome,
    i.nome || ' ' || i.sobrenome AS instrutor_nome
FROM
    Cursos c
INNER JOIN Categorias z ON c.categoria_id = z.categoria_id
INNER JOIN Instrutores i ON c.instrutor_id = i.instrutor_id;

-- Consulta 2: Busca alunos matriculados em um Curso específico
SELECT
    a.aluno_id,
    a.nome,
    a.email,
    m.data_matricula
FROM
    Alunos a
INNER JOIN Matriculas m ON a.aluno_id = m.aluno_id
WHERE
    m.curso_id = 1; -- Só puxa o aluno com id 1

-- Consulta 3: Puxa todas as aulas de um Curso em ordem
SELECT
    m.titulo AS modulo_titulo,
    m.ordem AS modulo_ordem,
    a.titulo AS aula_titulo,
    a.ordem AS aula_ordem,
    a.tipo AS tipo_aula
FROM
    Aulas a
INNER JOIN Modulos m ON a.modulo_id = m.modulo_id
WHERE
    m.curso_id = 1 -- Só puxa o curso com id 1
ORDER BY
    m.ordem, a.ordem;

-----------------------------
-- Consultas com agregação --
-----------------------------

-- Consulta 4: Vê a média de avaliações por curso
SELECT
    c.titulo,
    ROUND((AVG(av.nota), 0), 2) AS media_avaliacoes
FROM
    Cursos c
LEFT JOIN Matriculas m ON c.curso_id = m.curso_id
LEFT JOIN Avaliacoes av ON m.matricula_id = av.matricula_id
GROUP BY
    c.titulo
ORDER BY
    media_avaliacoes DESC;

-- Consulta 5: Conta quantos alunos tem por curso e ordena
SELECT
    c.titulo,
    COUNT(m.aluno_id) AS quantidade_alunos
FROM
    Cursos c
LEFT JOIN Matriculas m ON c.curso_id = m.curso_id
GROUP BY
    c.titulo
ORDER BY
    quantidade_alunos DESC;

-- Consulta 6: Mostra o curso que tem mais matriculas ATIVAS
SELECT
    c.titulo
    COUNT(m.matricula_id) AS quantidade_matriculas
FROM
    Cursos c 
INNER JOIN 
    Matriculas m ON c.curso_id = m.curso_id
WHERE
    m.status_matricula = 'Ativa'
ORDER BY
    quantidade_matriculas DESC
LIMIT 1;

-- Consulta 7: Mostra as categorias de curso que mais faturaram 
SELECT
    cat.nome,
    SUM(m.valor_pago) AS valor_total
FROM 
    Categorias cat
JOIN
    Cursos c ON cat.categoria_id = c.categoria_id
JOIN
    Matriculas m ON c.curso_id = m.curso_id
GROUP BY
    cat.nome
ORDER BY
    faturalmento_total DESC;

-----------------------------
-- Consultas de relatórios --
-----------------------------

-- Consulta 8: Listar alunos, cursos matriculados e porcentagem de conclusão 
WITH AulasPorCurso AS (
    SELECT
        m.curso_id,
        COUNT(a.aulas_id) AS total_aulas
    FROM Modulos m
    JOIN Aulas a ON m.modulo_id = a.modulo_id
    GROUP BY m.curso_id;
)

WITH AulasConcluidasPorMatricula AS(
    SELECT
        matricula_id,
        COUNT(progresso_id) AS aulas_concluidas
    FROM Progresso_Aulas
    WHERE concluida = TRUE 
    GROUP BY matricula_id
)

SELECT
    al.nome || ' ' || a.sobrenome AS aluno,
    c.titulo AS curso,
    m.status_matricula AS status,
    ac.aulas_concluidas AS aulas_concluidas,
    apc.total_aulas,
    ROUND(ac.aulas_concluidas / apc.total_aulas) * 100 AS porcentagem_conclusao
FROM Matriculas m  
JOIN Alunos al ON m.aluno_id = al.aluno_id
JOIN Cursos c ON m.curso_id = c.curso_id
JOIN AulasPorCurso apc ON m.curso_id = apc.curso_id
LEFT JOIN AulasConcluidasPorMatricula ac ON m.matricula_id = ac.matricula_id
ORDER BY
    aluno, curso;

-- Consulta 9: Relatório completo de um curso: instrutor, número de alunos, média de avaliações, faturamento
SELECT
    c.titulo AS curso_titulo,
    i.nome || ' ' || i.sobrenome AS instrutor_nome,
    (SELECT COUNT(*) FROM Matriculas WHERE curso_id = c.curso_id) AS total_alunos,
    (SELECT AVG(nota) FROM Avaliacoes av JOIN Matriculas m ON av.matricula_id = m.matricula_id WHERE m.curso_id = c.curso_id) AS media_geral,
    (SELECT SUM(valor_pago) FROM Matriculas WHERE curso_id = c.curso_id) AS valor_faturado,
FROM
    Cursos c
JOIN Instrutores i ON c.instrutor_id = i.instrutor_id
WHERE c.curso = 1; -- Busca apenas de um curso;

-- Consulta 10:




-- Consulta 8 : Lista todos os alunos que não concluiram o curso nos ultimos 6 meses
SELECT
    aluno_id,
    nome,
    email
FROM
    Alunos
WHERE
    aluno_id NOT IN (
        SELECT DISTINCT aluno_id
        FROM Matriculas
        WHERE status_matricula = 'Concluído'
        AND data_conclusao >= NOW() - INTERVAL '6 months'
    );

-- 