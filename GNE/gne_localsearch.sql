--R integer[], nElem integer, lambda float8, id_center int, radius float8
CREATE OR REPLACE FUNCTION GNE_LOCALSEARCH(nElem integer, lambda float8, id_center int, radius float8, R integer[])
	RETURNS integer[] AS
$$
DECLARE
	R_LINHA integer[];
	R_LINHA2 integer[];

	i integer;
	j integer;
	
	fR float8;
	fR_Linha float8;
	fR_Linha2 float8;
	
 	C1 CURSOR(ID_PARAMETRO INTEGER) FOR SELECT id_ft_2 FROM 
			(SELECT id_ft_2, (cube(c3.feature) <-> cube(ft_Items)) AS DIST_2 FROM 
				(SELECT id_ft_2, ft_Items FROM 
					( SELECT (cube(c1.feature) <-> cube(c2.feature)) AS DIST, c2.id_ft as id_ft_2, c2.feature as ft_Items
					 FROM COLOR c1, COLOR c2
					 WHERE c1.id_ft = $3
					) AS itens_mais_proximos_do_centro
				WHERE dist <= $4 AND (id_ft_2 != ALL ($5))
				) AS itens_diversos_do_elemento_selecionado, COLOR C3
			WHERE C3.id_ft = ID_PARAMETRO
			ORDER BY DIST_2 DESC
			LIMIT $1
			) 
		AS os_n_elementos_mais_diversos;
	R1 record;
BEGIN
	-- VALOR DO CONJUNTO R, RETORNADO DA CONSTRUÇÃO, APÓS A FUNÇÃO DE AVALIAÇÃO
	fR := getValueF_Avaliation($1, $2, $3, R);
	-- VALOR DO CONJUNTO AUXILIAR R' 
	fR_Linha := -9999;

	FOR i IN 1..(CARDINALITY($5)-1) LOOP
		FOR j IN (i+1)..CARDINALITY($5) LOOP
			-- CONJUNTO AUXILIAR
			-- SERÁ DO CONJUNTO R_LINHA QUE AO FINAL, SE TORNARÁ, O CONJUNTO DE SAÍDA R
			R_LINHA := R;
				
			FOR R1 IN C1(R_Linha[i]) LOOP				
				R_LINHA2 := R_LINHA;
				
				-- SEGUNDO CONJUNTO AUXILIAR, MAS ESTE TEM UM DOS ITENS COMUTADOS.
				R_LINHA2[J] := R1.id_ft_2;
				-- AVALIAÇÃO DO SEGUNDO CONJUNTO
				fR_Linha2 := getValueF_Avaliation($1, $2, $3, R_LINHA2);
				-- SE O VALOR DE AVALIAÇÃO DO SEGUNDO CONJUNTO FOR MELHOR QUE O PRIMEIRO,
				-- OCORRE UMA MELHORA NA RESPOSTA DA FUNÇÃO.
				IF ( fR_Linha2 < fR_Linha) THEN
					R_LINHA := R_LINHA2;
					fR_Linha := fR_Linha2;
				END IF;
			END LOOP;
		END LOOP;
		
		-- HOUVE FINALIMENTE UMA MELHORA, O CONJUNTO R SE TORNA O R_LINHA.
		IF fR_Linha < fR THEN
			R := R_Linha;
			fR := fR_Linha;
		END IF;
		
	END LOOP;
	
	RETURN R;
END
$$ LANGUAGE PLPGSQL;

do
$$
DECLARE
	R integer[];
	i integer;
BEGIN
	R := array[36558,37152,36723];
	
	R := gne_localsearch(R, 3, 0.3, 36642);
	
	FOREACH i IN ARRAY R LOOP
		raise notice 'R: %.', i;
	END LOOP;
END
$$ LANGUAGE PLPGSQL


SELECT id_ft_2 FROM 
			(SELECT id_ft_2, (cube(c3.feature) <-> cube(ft_Items)) AS DIST_2 FROM 
				(SELECT id_ft_2, ft_Items FROM 
					( SELECT (cube(c1.feature) <-> cube(c2.feature)) AS DIST, c2.id_ft as id_ft_2, c2.feature as ft_Items
					 FROM COLOR c1, COLOR c2
					 WHERE c1.id_ft = 36652
					) AS itens_mais_proximos_do_centro
				WHERE dist <= 300 AND (id_ft_2 != ALL (array[36558,37152,36723]))
				) AS itens_diversos_do_elemento_selecionado, COLOR C3
			WHERE C3.id_ft = 37152
			ORDER BY DIST_2 DESC
			LIMIT 3
			) 
		AS os_n_elementos_mais_diversos;
