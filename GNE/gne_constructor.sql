/*
	Construção do algoritmo GNE(Grasp with neighborhood expansion)
	Função de construção
	Entrada: nElem - k
			 alfa  - aleatoriedade para construção de RCL
			 id_ft - o centro da consulta
			 radius - raio da consulta
			 lambda - constante de diversidade
	Saída: R - Conjunto inicial para busca local
*/

DROP FUNCTION gne_constructor;

CREATE OR REPLACE FUNCTION gne_constructor(nElem int, lambda float8, id_center int, radius float8, alfa float8) 
RETURNS int[] AS
$$
DECLARE	
	id_ft int[];  --O ID
	mmc	float8[]; --O VALOR DE CADA MMC PARA CADA ID
	
	RCL int[];    --A LISTA DOS ITENS ALFA
	R int[];      --O RETORNO DO CONSTRUTOR
	
	id_ft_max int; -- O ID DO MAIOR VALOR DE MMC
	id_ft_min int; -- O ID DO MENOR VALOR DE MMC
	mmc_max float8; -- O MAIOR VALOR DE MMC
	mmc_min float8; -- O MENOR VALOR DE MMC
	
	C1 CURSOR FOR SELECT * FROM rangeqcl2($3,$4);
	
	--VALORES
	p_mmc int;
	l_mmc int;
	
	k_construct float8;
	
	i int;
BEGIN
 	p_mmc := 1;
	
	-- ENQUANTO O CONJUNTO R NÃO FOR COMPLETO
	-- CONTINUE FAZENDO
	WHILE cardinality(R) IS NULL OR cardinality(R) < $1 LOOP 
		mmc_max := -9999;
		mmc_min := 9999;
		i := 1;
		id_ft := NULL;
		mmc := NULL;
		RCL := NULL;
		
		/*
		CÁLCULO DE TODOS OS VALORES DE MMC EM S
		*/
		FOR R1 IN C1 LOOP
			-- SALVO OS IDs COM SEUS RESPECTIVOS MMC
			IF array_position(R, R1.id_ft) IS NULL THEN
				id_ft := array_append(id_ft, R1.id_ft);
				l_mmc := $1 - p_mmc;
				mmc := array_append(mmc, getmmc ($1, $2, R1.id_ft, R1.dist, R, l_mmc));
				
				-- SALVAR O VALOR DE MMC MÍNIMO E MÁXIMO PARA GERAR A LISTA RLC
				IF ( mmc[i] > mmc_max) THEN
					mmc_max := mmc[i];
				END IF;	

				IF ( mmc[i] < mmc_min) THEN
					mmc_min := mmc[i];			
				END IF;

				i := i + 1;
			END IF;
		END LOOP;
		
		/*
		CÁLCULO DA LISTA RCL						
		*/
		-- CRIA O LIMIAR MÁXIMO PARA O VALOR DO MMC
		k_construct := mmc_max - $5 * (mmc_max - mmc_min);
		
		-- CRIAR A LISTA RCL
		i := 1;
		WHILE i <= cardinality(mmc) LOOP
			IF (mmc[i] <= k_construct) THEN
				-- AMBOS OS VETOR, NUMA MESMA POSIÇÃO TEM ID E O MMC CORRESPONDENTE A ESSE ID
				RCL := array_append(RCL, id_ft[i]);
			END IF;
			i := i + 1;
		END LOOP;
		
		-- ADICIONANDO UM DOS ITENS ALEATÓRIAMENTE DA LISTA RCL
		IF CARDINALITY(RCL) IS NOT NULL AND CARDINALITY(RCL) > 1 THEN
			
			-- SELECIONA UM ITEM RANDOMICO EM RCL E ADICIONA NO CONJUNTO DE SAÍDA R.
			SELECT random()*(CARDINALITY(RCL) - 1) + 1 INTO i;
			R := array_append(R, RCL[i]);

		ELSIF CARDINALITY(RCL) = 1 THEN
		
			-- SE HOUVER APENAS 1 ELEMENTO
			R := array_append(R, RCL[1]);			
		ELSE 
			RAISE NOTICE '--- ERROR ---';
		END IF;
		
		p_mmc := p_mmc + 1;
	END LOOP;
	
	RETURN R;
END
$$ LANGUAGE PLPGSQL	;


do
$$
DECLARE 
	ret int[];
	ele int;
BEGIN
	ret := gne_constructor(3, 0.3, 36642, 300, 0.3);
	
	FOREACH ele IN ARRAY ret LOOP
		raise notice 'ret: %.', ele;
	END LOOP;
END
$$ LANGUAGE PLPGSQL;
