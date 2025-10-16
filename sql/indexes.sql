--------------------------------------------------------------
-- Criando views para as tabelas que mais serão consultadas --
--------------------------------------------------------------

-- Para facilitar a consulta para a tabela de cursos, ela vai conseguir buscar as categorias e instrutor mais rápido
CREATE INDEX idx_cursos_categoria_id ON Cursos(categoria_id);
CREATE INDEX idx_cursos_instrutor_id ON Cursos(instrutor_id);

-- Para conseguir encontrar todos os modulos de um curso
CREATE INDEX idx_modulos_curso_id ON Modulos(curso_id);

-- Para facilitar a busca de todas as aulas de um modulo
CREATE INDEX idx_aulas_modulo_id ON Aulas(modulo_id);

-- Para facilitar as buscas na tabela de matriculas
CREATE INDEX idx_matriculas_aluno_id ON Matriculas(aluno_id);
CREATE INDEX idx_matriculas_curso_id ON Matriculas(curso_id);

-- Como a tabela de progresso_aulas será grande, é importante fazer um index para ela
CREATE INDEX idx_progresso_matricula_id ON Progresso_Aulas(matricula_id);
CREATE INDEX idx_progresso_aula_id ON Progresso_Aulas(aula_id);