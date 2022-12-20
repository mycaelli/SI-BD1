# Manipulação do banco conflito para ACH2004 em Mysql
#
# Mycaelli Cerqueira de Lima - 10723562


##################################################################################################################################################################

# 1.a - Exclusividade da hierarquia de conflitos

Na tabela conflitos ID_Conflito foi implementado como chave primária o que garante a exclusividade de cada ID para cada conflito adicionado ao banco.

##################################################################################################################################################################

# 1.b - Uma divisão é dirigida por três chefes militares como máximo

CREATE OR REPLACE TRIGGER taddlideradivisao(
    BEFORE INSERT
    ON CHEFEM_LIDERA
    BEGIN
    IF EXISTS (SELECT DIVISAO.ID_Divisao, DIVISA0.Contador
                    FROM DIVISAO 
                    WHERE CHEFEM_LIDERA.ID_Divisao == DIVISA0.ID_Divisao AND DIVISAO.contador = 3) 
    THEN 
        RAISE_APPLICATION_ERROR(-20000,
                 'Divisão não pode ter mais do que 3 líderes');
    ELSIF EXISTS (SELECT DIVISAO.ID_Divisao, DIVISA0.Contador
                    FROM DIVISAO 
                    WHERE CHEFEM_LIDERA.ID_Divisao == DIVISA0.ID_Divisao AND DIVISAO.contador < 3) 
    THEN
        UPDATE DIVISAO
        SET contador = contador + 1
        WHERE DIVISAO.ID_Divisao = CHEFEM_LIDERA.ID_Divisao;
    END IF;
    END;
);

CREATE OR REPLACE TRIGGER tremovelideradivisao(
    BEFORE DELETE
    ON CHEFEM_LIDERA
    BEGIN
    IF EXISTS (SELECT DIVISAO.ID_Divisao, DIVISA0.Contador
                    FROM DIVISAO 
                    WHERE CHEFEM_LIDERA.ID_Divisao == DIVISA0.ID_Divisao) 
    THEN
        UPDATE DIVISAO
        SET contador = contador - 1
        WHERE DIVISAO.ID_Divisao = CHEFEM_LIDERA.ID_Divisao;
    END IF;
    END;
);

##################################################################################################################################################################

# 1.c - Em um conflito armado participam como mínimo dois grupos armados

CREATE OR REPLACE TRIGGER taddparticipaconflito(
    AFTER INSERT
    ON GRUPO_CONFLITO
    BEGIN
    IF EXISTS (SELECT CONFLITO.ID_Conflito
                FROM CONFLITO
                WHERE CONFLITO.ID_Conflito = GRUPO_CONFLITO.ID_Conflito AND CONFLITO.Contador < 2) 
    THEN
        UPDATE CONFLITO
        SET contador = contador + 1
        WHERE CONFLITO.ID_Conflito = GRUPO_CONFLITO.ID_Conflito;
        DBMS_OUTPUT.PUT_LINE(‘Adicione pelo menos mais um grupo para compor o conflito’);
    END IF;
    END;
);

CREATE OR REPLACE TRIGGER tremoveparticipaconflito(
    BEFORE DELETE
    ON GRUPO_CONFLITO
    BEGIN
    IF EXISTS (SELECT CONFLITO.ID_Conflito
                FROM CONFLITO
                WHERE CONFLITO.ID_Conflito = GRUPO_CONFLITO.ID_Conflito AND CONFLITO.Contador <= 2) 
    THEN
        RAISE_APPLICATION_ERROR(-20001
                , 'Conflito não pode possuir menos do que dois grupos participantes');
    ELSIF
        UPDATE CONFLITO
        SET contador = contador - 1
        WHERE CONFLITO.ID_Conflito = GRUPO_CONFLITO.ID_Conflito;
    END IF;
    END;
);

##################################################################################################################################################################

# 1.d - Com um disparador (trigger), procedimento armazenado o dentro do código dos programas você deveria: 
    # Manter a consistência das baixas totais em cada grupo armado, a partir das baixas produzidas nas suas divisões; 
    #gerar e assegurar a sequencialidade do número de divisão dentro do grupo armado

# gerar e assegurar a sequencialidade do número de divisão dentro do grupo armado

CREATE SEQUENCE seq_divisao
    MINVALUE 1
    START WITH 1
    INCREMENT BY 1;

# Manter a consistência das baixas totais em cada grupo armado, a partir das baixas produzidas nas suas divisões

CREATE OR REPLACE TRIGGER tbaixas(
    AFTER INSERT OR UPDATE Or DELETE OF Baixas
    ON DIVISAO 
    REFERENCING NEW AS NEW OLD AS OLD
    BEGIN
    IF INSERTING 
    THEN
        UPDATE GRUPO_ARMADO 
        SET GRUPO_ARMADO.Baixas_Totais = GRUPO_ARMADO.Baixas_Totais + :NEW.Baixas
        WHERE GRUPO_ARMADO.ID_Grupo = DIVISA0.ID_Grupo;
    ELSIF UPDATING
    THEN
        UPDATE GRUPO_ARMADO
        SET GRUPO_ARMADO.Baixas_Totais = GRUPO_ARMADO.Baixas_Totais - :OLD.Baixas
        WHERE GRUPO_ARMADO.ID_Grupo = DIVISA0.ID_Grupo;
        UPDATE GRUPO_ARMADO
        SET GRUPO_ARMADO.Baixas_Totais = GRUPO_ARMADO.Baixas_Totais + :NEW.Baixas
        WHERE GRUPO_ARMADO.ID_Grupo = DIVISA0.ID_Grupo;
    ELSE
        UPDATE GRUPO_ARMADO
        SET GRUPO_ARMADO.Baixas_Totais = GRUPO_ARMADO.Baixas_Totais - :OLD.Baixas
        WHERE GRUPO_ARMADO.ID_Grupo = DIVISA0.ID_Grupo;
);

##################################################################################################################################################################

# 2.a - Permita cadastrar divisões dentro de um grupo militar, cadastre conflitos bélicos, grupos militares, líderes políticos e chefes militares


INSERT INTO GRUPO_ARMADO(ID_Grupo, Nome, Baixas_Totais) VALUES (1, 'GrupoArmado1', 0);
INSERT INTO DIVISAO(ID_Divisao, ID_Grupo, Baixas, Barcos, Homens, Tanques, Aviões, Contador) VALUES (seq_divisao.nextval, 1, 10, 30, 100, 5, 2, 0);
INSERT INTO DIVISAO(ID_Divisao, ID_Grupo, Baixas, Barcos, Homens, Tanques, Aviões, Contador) VALUES (seq_divisao.nextval, 1, 2, 5, 25, 0, 0, 0);
INSERT INTO LIDER_POLITICO(Nome, Apoios, ID_Grupo) VALUES ('Robson I', 'Apoiado por Cuba e Suiça', 1);
INSERT INTO CHEFE_MILITAR(ID_Chefe_Militar, Hierarquia, Lider_Politico) VALUES (234, 'Coronel', 'Robson I');
INSERT INTO CHEFE_MILITAR(ID_Chefe_Militar, Hierarquia, Lider_Politico) VALUES (654, 'Capitão', 'Robson I');
INSERT INTO CHEFEM_LIDERA(ID_Divisao, ID_Grupo, ID_Chefe_Militar) VALUES (1, 1, 234);
INSERT INTO CHEFEM_LIDERA(ID_Divisao, ID_Grupo, ID_Chefe_Militar) VALUES (2, 1, 654);

INSERT INTO TRAFICANTE_DE_ARMAS(Traficante_ID, Nome_Traficante) VALUES (555, 'Karlos Silva');
INSERT INTO ARMA(Arma_ID, Nome, Tipo_Arma, Capacidade_Destrutiva, Traficante_ID, Quantidade_Total) VALUES (1, 'Bazuca', 'Arma de fogo ', 87, 555, 30);
INSERT INTO FORNECE_ARMAS(Nome_Traficante, ID_Grupo, Quantidade, Arma_ID) VALUES (555, 1, 17, 1);


INSERT INTO GRUPO_ARMADO(ID_Grupo, Nome, Baixas_Totais) VALUES (2, 'GrupoArmado2', 0);
INSERT INTO DIVISAO(ID_Divisao, ID_Grupo, Baixas, Barcos, Homens, Tanques, Aviões, Contador) VALUES (seq_divisao.nextval, 2, 13, 18, 78, 1, 3, 0);
INSERT INTO DIVISAO(ID_Divisao, ID_Grupo, Baixas, Barcos, Homens, Tanques, Aviões, Contador) VALUES (seq_divisao.nextval, 2, 35, 12, 124, 7, 0, 0);
INSERT INTO DIVISAO(ID_Divisao, ID_Grupo, Baixas, Barcos, Homens, Tanques, Aviões, Contador) VALUES (seq_divisao.nextval, 2, 2, 0, 7, 0, 0, 0);
INSERT INTO LIDER_POLITICO(Nome, Apoios, ID_Grupo) VALUES ('Ricardo II', 'Apoiado por Argentina, Uruguai e Chile', 2);
INSERT INTO CHEFE_MILITAR(ID_Chefe_Militar, Hierarquia, Lider_Politico) VALUES (834, 'Coronel', 'Ricardo II');
INSERT INTO CHEFE_MILITAR(ID_Chefe_Militar, Hierarquia, Lider_Politico) VALUES (572, 'Capitão', 'Ricardo II');
INSERT INTO CHEFE_MILITAR(ID_Chefe_Militar, Hierarquia, Lider_Politico) VALUES (742, 'Coronel', 'Ricardo II');
INSERT INTO CHEFE_MILITAR(ID_Chefe_Militar, Hierarquia, Lider_Politico) VALUES (495, 'Capitão', 'Ricardo II');
INSERT INTO CHEFEM_LIDERA(ID_Divisao, ID_Grupo, ID_Chefe_Militar) VALUES (3, 2, 834);
INSERT INTO CHEFEM_LIDERA(ID_Divisao, ID_Grupo, ID_Chefe_Militar) VALUES (3, 2, 572);
INSERT INTO CHEFEM_LIDERA(ID_Divisao, ID_Grupo, ID_Chefe_Militar) VALUES (4, 2, 742);
INSERT INTO CHEFEM_LIDERA(ID_Divisao, ID_Grupo, ID_Chefe_Militar) VALUES (5, 2, 495);


INSERT INTO TRAFICANTE_DE_ARMAS(Traficante_ID, Nome_Traficante) VALUES (987, 'Bruno Nogueira');
INSERT INTO ARMA(Arma_ID, Nome, Tipo_Arma, Capacidade_Destrutiva, Traficante_ID, Quantidade_Total) VALUES (2, 'Metralhadora', 'Arma de fogo ', 73, 987, 287);
INSERT INTO FORNECE_ARMAS(Traficante_ID, ID_Grupo, Quantidade, Arma_ID) VALUES (987, 2, 79, 2);


INSERT INTO CONFLITO(ID_Conflito, Mortos, Feridos, Nome, Contador, Tipo_Conflito) VALUES (101, 12, 43, 'Batalha101', 0, 1);
INSERT INTO CONFLITO_RELIGIOSO(ID_Conflito, Religiao) VALUES (101, 'Cristianismo');
INSERT INTO CONFLITO_RELIGIOSO(ID_Conflito, Religiao) VALUES (101, 'Judaismo');
INSERT INTO PAIS_AFETADO(Pais, ID_Conflito) VALUES ('Canada', 101);
INSERT INTO PAIS_AFETADO(Pais, ID_Conflito) VALUES ('México', 101);
INSERT INTO PAIS_AFETADO(Pais, ID_Conflito) VALUES ('Estados Unidos', 101);
INSERT INTO GRUPO_CONFLITO(ID_Conflito, ID_Grupo, Data_Saida, Data_Entrada) VALUES (101, 1, '2019-04-23', '2022-01-01');
INSERT INTO GRUPO_CONFLITO(ID_Conflito, ID_Grupo, Data_Saida, Data_Entrada) VALUES (101, 2, '2019-04-23', '2022-01-01');


##################################################################################################################################################################

# 2.b.i - Gerar um gráfico, histograma, por tipo de conflito e número de conflitos

    Tipos de conflito:
        # RELIGIOSO 1
        # TERRITORIAL 2
        # MATERIA PRIMA 3
        # RACIAL 4 
SELECT Tipo_Conflito, COUNT(Tipo_Conflito)
FROM CONFLITO
GROUP BY Tipo_Conflito;

##################################################################################################################################################################

# 2.b.ii - Listar os traficantes e os grupos armados (Nome) para os quais os traficantes fornecem armas “Barret M82” ou “M200 intervention”

SELECT Nome_Traficante, Nome
FROM (FORNECE_ARMAS NATURAL JOIN ARMA) NATURAL JOIN GRUPO_ARMADO 
WHERE Nome_Arma = “Barret M82” OR Nome_Arma = “M200 intervention”;

##################################################################################################################################################################

# 2.b.iii - Listar os 5 maiores conflitos em número de mortos

SELECT C.Nome
FROM Conflito C
ORDER BY C.Mortos DESC LIMIT 5;

##################################################################################################################################################################

# 2.b.iv - Listar as 5 maiores organizações em número de mediações

SELECT M.Nome, COUNT(D.ID_Organizacao_Mediadora) AS Mediações
FROM ORGANIZACAO_MEDIADORA M, DIALOGA D
ORDER BY COUNT(D.ID_Organizacao_Mediadora) DESC LIMIT 5;

##################################################################################################################################################################

# 2.b.v - Listar os 5 maiores grupos armados com maior número de armas fornecidos

SELECT G.Nome, COUNT(A.ID_Grupo) AS Armas_Fornecidas
FROM GRUPO_ARMADO G, FORNECE_ARMAS A
ORDER BY COUNT(A.ID_Grupo) DESC LIMIT 5;

##################################################################################################################################################################

# 2.b.vi - Listar o país e número de conflitos com maior número de conflitos religiosos

SELECT Pais, COUNT(C.ID_Conflito) AS Conflitos
FROM PAIS_AFETADO P, CONFLITO_RELIGIOSO C
WHERE P.ID_Conflito = C.ID_Conflito AND Conflitos >= ALL(SELECT COUNT(ID_Conflito)
                                                     FROM CONFLITO_RELIGIOSO);

##################################################################################################################################################################
