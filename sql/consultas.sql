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