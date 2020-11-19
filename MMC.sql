/* CÁLCULO DO MMC DE CADA ITEM RETORNADO NA CONSULTA
Entrada - id_ft: id do elemento avaliado;
		- lambda: fator de diversidade;
		- dist: distância do item ao centro da consulta, ou seja, delta sim;
		- nElem: k, ou seja, |R| final
		- p: |R| = p - 1, 1 <= p <= k
		- l: k - p, ou seja, se k for 5, quando o conjunto R estiver vazio l = 4, pois p começa em 1.
		
Saida   - ret: valor da função mmc
*/

DROP FUNCTION getmmc;

CREATE OR REPLACE FUNCTION getmmc(id_ft INTEGER, lambda FLOAT8, dist_P FLOAT8, R integer[], l integer, nElem integer)
RETURNS float8 AS 
$$
DECLARE
	sim2 float8; -- Valor da segunda parcela do MMC
	simF float8; -- Valor da terceira parcela do MMC
	ret float8;  -- Valor do MMC
	
	cdAux integer; -- Variável auxiliar para percorrer os dados em R
	
	k1 float8; -- Constante 1 do MMC
	k2 float8; -- Constante 2 do MMC
BEGIN	
	/*SEGUNDA PARCELA DO MMC
		CÁLCULO DA DIVERSIDADE DO CONJUNTO R
		
		SE R NÃO FOR NULO, POIS NA PRIMEIRA ITERAÇÃO DO CONSTRUTOR NÃO HÁ NENHUM ELEMENTO.
	*/
	IF $4 IS NOT NULL THEN
	
-- 		CALCULO A DIVERSIDADE DO CONJUNTO R
		
		SELECT SUM(dist) INTO sim2 FROM
			(SELECT c1.id_ft as idc, (cube(c1.feature) <-> cube(c2.feature)) as dist
			 FROM COLOR C1, COLOR C2
			 WHERE c2.id_ft = ANY ($4) AND c1.id_ft = $1
			) AS Q
		GROUP BY idc; 
	ELSE
-- 		SE NÃO HOUVER NENHUM ELEMENTO EM R, A DIVERSIDADE EM RELAÇÃO DO CONJUNTO É NULA.	

		sim2 := 0;
	END IF;
	
	/*TERCEIRA PARCELA DO MMC
		Diversidade do conjunto S sem levar em conta si e R.
		
		NA ÚLTIMA ITERAÇÃO, QUANDO R ESTIVER APENAS COM UM ELEMENTO FALTANTE, A DIVERSIDADE EM RELAÇÃO AO UNIVERSO É 0
	*/
	IF $5 > 0 THEN
		/*
			O CÁLCULO DA ÚLTIMA PARCELA NÃO LEVA EM CONTA A DIVERSIDADE DOS ELEMENTOS DO UNIVERSO QUE JÁ FORAM ADICIONADOS EM R
			SE NÃO HOUVER NENHUM ELEMENTO EM R, A QUERY RETORNA NULL POIS HÁ UMA COMPARAÇÃO INVÁLIDA
		*/
		IF $4 IS NOT NULL THEN
			SELECT SUM(dist) INTO simF FROM
				(SELECT c1.id_ft as idc, (cube(c1.feature) <-> cube(c2.feature)) as dist
				 FROM COLOR C1, COLOR C2
				 WHERE (c2.id_ft != ALL ($4)) AND c1.id_ft = $1
				 ORDER BY dist DESC
				 LIMIT $5
				 ) AS Q
			GROUP BY idc;
		ELSE 
			SELECT SUM(dist) INTO simF FROM
				(SELECT c1.id_ft as idc, (cube(c1.feature) <-> cube(c2.feature)) as dist
				 FROM COLOR C1, COLOR C2
				 WHERE c1.id_ft = $1
				 ORDER BY dist DESC
				 LIMIT $5
				 ) AS Q
			GROUP BY idc;
		END IF;
	ELSE 
		simF := 0;
	END IF;
	
	/*
		FIM DO ALGORITMO
		CÁLCULO DAS CONSTANTES E DO MMC
	*/
	k1 = 1 - $2;
	k2 = $2 / ($6  - 1);
	
	ret := k1 * $3 - (k2 * sim2) - ( k2 * simF );
	RETURN ret;
END
$$ LANGUAGE PLPGSQL;

do $$
BEGIN 
	raise notice '%.', getmmc(36642, 0.3, 0, null, 0, 3);
END
$$ LANGUAGE PLPGSQL
