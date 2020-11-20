
CREATE OR REPLACE FUNCTION SimulatedAnnealig(nIt_GRASP int, nElem int, lambda float8, id_center int, radius float8, alfa_GRASP float8, 
											 	SAMax int, alfa float8, T_ini float8)
RETURNS integer[] AS
$$
DECLARE
	R integer[];
	R_1 integer[];
	R_Final integer[];
	
	fValueR float8;
	fValueR_1 float8;
	random float8;
	decaimento float8;
	
	i integer;
	Temperatura float8;
BEGIN
	R := getGrasp($1, $2, $3, $4, $5, $6);
	R_Final := R;
	
	fValueR := getValueF_Avaliation($2,$3,$4, R);
	raise notice 'Valor GRASP: %.', fValueR;
	Temperatura := $9;
		
	i := 1;
	WHILE Temperatura > 0.001 LOOP
		WHILE i <= $7 LOOP
			i := i + 1;
			
			R_1 := GNE_LOCALSEARCH($2, $3, $4, $5, R);
			
			fValueR_1 := getValueF_Avaliation($2,$3,$4,R_1);
			
			IF fValueR_1 < fValueR THEN
				R_Final := R_1;
				fValueR := fValueR_1;
			ELSE
				SELECT random() INTO random;
				decaimento := exp((-(fValueR_1 - fValueR))/Temperatura);
				
				IF (decaimento > random) THEN
					R := R_1;
				END IF;
			END IF;
		END LOOP;
		
		Temperatura := $8 * Temperatura;
		i := 1;		
	END LOOP;
	
	fValueR := getValueF_Avaliation($2, $3, $4, R);
	fValueR_1 := getValueF_Avaliation($2, $3, $4, R_Final);
	if( fValueR_1 < fValueR) THEN
		R_Final := R;
	else
		fValueR := fValueR_1;
	end if;
	
	raise notice 'Valor SA: %', fValueR;
	RETURN R_FINAL;
	
END
$$ LANGUAGE PLPGSQL;

EXPLAIN ANALYZE SELECT * FROM SimulatedAnnealig(5, 3, 0.3, 36642, 450.0, 0.3, 10, 0.5, 100);
