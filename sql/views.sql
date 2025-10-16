-- Criando views para consultas que podem ser mais relevantes

-- View para verificar a lista de cursos dado uma categoria ou professor
CREATE VIEW Lista_Cursos AS
SELECT
    c.curso_id,
    c.titulo,
    c.preco,
    c.carga_horaria,
    c.nivel,
    cat.nome AS categoria,
    i.nome || ' ' || i.sobrenome AS instrutor
FROM
    Cursos c
JOIN
    Categorias cat ON c.categoria_id = cat.categoria_id
JOIN
    Instrrutores i ON c.instrutor_id = i.instrutor_id;
