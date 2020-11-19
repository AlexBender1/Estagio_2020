CREATE OR REPLACE FUNCTION GNE_LOCALSEARCH(R integer[], nElem integer, lambda float8, id_ft int)
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
	
 	C1 CURSOR (ID_PARAMETRO integer) FOR SELECT ID_2 FROM (
			SELECT c2.id_ft as ID_2, (cube(c1.feature) <-> cube(c2.feature)) as dist
			FROM COLOR C1, COLOR C2
			WHERE c1.id_ft = ID_PARAMETRO AND (c2.id_ft != ALL ($1))
			ORDER BY dist DESC
			LIMIT $2
		) AS Q;
	R1 record;
BEGIN
	-- VALOR DO CONJUNTO R, RETORNADO DA CONSTRUÇÃO, APÓS A FUNÇÃO DE AVALIAÇÃO
	fR := getValueF_Avaliation(R, $3, $2, $4);
	-- VALOR DO CONJUNTO AUXILIAR R' 
	fR_Linha := -9999;

	FOR i IN 1..(CARDINALITY($1)-1) LOOP
		FOR j IN (i+1)..CARDINALITY($1) LOOP
			-- CONJUNTO AUXILIAR
			-- SERÁ DO CONJUNTO R_LINHA QUE AO FINAL, SE TORNARÁ, O CONJUNTO DE SAÍDA R
			R_LINHA := R;
				
			FOR R1 IN C1(R_Linha[i]) LOOP				
				R_LINHA2 := R_LINHA;
				
				-- SEGUNDO CONJUNTO AUXILIAR, MAS ESTE TEM UM DOS ITENS COMUTADOS.
				R_LINHA2[J] := R1.ID_2;
				-- AVALIAÇÃO DO SEGUNDO CONJUNTO
				fR_Linha2 := getValueF_Avaliation(R_LINHA2, $3, $2, $4);
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
