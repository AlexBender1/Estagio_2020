DROP FUNCTION GRASP;
CREATE OR REPLACE FUNCTION GRASP(nIt int, nElem int, lambda float8, id_center int, radius float8, alfa float8) 
	RETURNS SETOF rqGrasp AS 
$$
DECLARE
	i int;
	
	R_Line integer[];
	R_Line2 integer[];
	R_Line2_value float8;
	
	R integer[];
	R_value float8;
BEGIN
	R_Value := -99999;
	FOR i IN 0..$1 LOOP
		-- GERA O CONJUNTO INICIAL
		R_Line := gne_constructor($2, $3, $4, $5, $6);
		-- GERA UM SEGUNDO CONJUNTO COM LOCAL SEARCH, PARA DESCOBRIR SE HOUVE UMA MELHORA EM RELAÇÃO AO MELHOR CONJUNTO JÁ AVALIADO
		R_Line2 := gne_localSearch($2, $3, $4, $5, R_Line);
		-- AVALIAÇÃO DO SEGUNDO CONJUNTO
		R_Line2_value := getValueF_Avaliation($2, $3, $4, R_Line2);
		-- SE O CONJUNTO FINAL DE SAÍDA R FOR VAZIO, R SE TORNA O R_LINE2 JÁ QUE O MELHOR VALOR ATÉ O MOMENTO
		-- SENÃO AVALIA SE O CONJUNTO DA BUSCA LOCAL FOI MELHOR QUE O VALOR ANTERIOR
		IF cardinality(R) IS NULL THEN
			R := R_Line2;
			R_Value := R_Line2_value;
		ELSIF R_Line2_value < R_value THEN
			R := R_Line2;						
			R_Value := R_Line2_value;
		END IF;	
	END LOOP;
	
	-- SAÍDA EM FORMATO DE QUERY
	FOREACH i IN ARRAY R LOOP
		RETURN NEXT i;
	END LOOP;
END
$$ LANGUAGE PLPGSQL;

/*
	ÚNICAMENTE PARA SAÍDA EM FORMATO DE VETOR E NÃO QUERY
*/
DROP FUNCTION getGrasp;
CREATE OR REPLACE FUNCTION getGRASP(nIt int, nElem int, lambda float8, id_center int, radius float8, alfa float8) 
	RETURNS integer[] AS 
$$
DECLARE
	i int;
	
	R_Line integer[];
	R_Line2 integer[];
	R_Line2_value float8;
	
	R integer[];
	R_value float8;
BEGIN
	R_Value := -99999;
	FOR i IN 0..$1 LOOP
		-- GERA O CONJUNTO INICIAL
		R_Line := gne_constructor($2, $3, $4, $5, $6);
		-- GERA UM SEGUNDO CONJUNTO COM LOCAL SEARCH, PARA DESCOBRIR SE HOUVE UMA MELHORA EM RELAÇÃO AO MELHOR CONJUNTO JÁ AVALIADO
		R_Line2 := gne_localSearch($2, $3, $4, $5, R_Line);
		-- AVALIAÇÃO DO SEGUNDO CONJUNTO
		R_Line2_value := getValueF_Avaliation($2, $3, $4, R_Line2);
		-- SE O CONJUNTO FINAL DE SAÍDA R FOR VAZIO, R SE TORNA O R_LINE2 JÁ QUE O MELHOR VALOR ATÉ O MOMENTO
		-- SENÃO AVALIA SE O CONJUNTO DA BUSCA LOCAL FOI MELHOR QUE O VALOR ANTERIOR
		IF cardinality(R) IS NULL THEN
			R := R_Line2;
			R_Value := R_Line2_value;
		ELSIF R_Line2_value < R_value THEN
			R := R_Line2;						
			R_Value := R_Line2_value;
		END IF;	
	END LOOP;
	
	RETURN R;
END
$$ LANGUAGE PLPGSQL;

EXPLAIN ANALYZE SELECT * FROM GRASP(5, 3, 0.3, 36642, 450.0, 0.3);

SELECT * FROM rangeqcl2(36642,450);