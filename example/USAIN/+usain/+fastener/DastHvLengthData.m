classdef DastHvLengthData < matlab.mixin.Copyable

    properties (Constant)
        BOLT_OPTIONS_ORDER = ["M36", "M42", "M48", "M56", "M64", "M72"]
    end

    methods (Static)

        function table = get_dast3a_table(~)
            % Table taken as direct copy->paste from TowerCalc `BoltExtenderLength.m` representing table3a from DASt.
            % The first column represents bolt lengths while the remaining columns represent the minimum and maximum
            % clamping lengths (hence a range) that would be suited for the bolt length.

            %  bolt        M36             M42             M48             M56             M64             M72
            %  length  min     max      min     max     min     max     min     max     min     max     min     max
            table = 1e-3 * [ ...
                85      43      48      nan     nan     nan     nan     nan     nan     nan     nan     nan     nan
                90      48      53      nan     nan     nan     nan     nan     nan     nan     nan     nan     nan
                95      53      58      nan     nan     nan     nan     nan     nan     nan     nan     nan     nan
                100     58      63      nan     nan     nan     nan     nan     nan     nan     nan     nan     nan
                105     63      68      nan     nan     nan     nan     nan     nan     nan     nan     nan     nan
                110     68      73      nan     nan     nan     nan     nan     nan     nan     nan     nan     nan
                115     73      78      nan     nan     nan     nan     nan     nan     nan     nan     nan     nan
                120     78      83      66      77      nan     nan     nan     nan     nan     nan     nan     nan
                125     83      88      71      82      nan     nan     nan     nan     nan     nan     nan     nan
                130     88      93      76      87      70      83      nan     nan     nan     nan     nan     nan
                135     93      98      81      92      75      88      nan     nan     nan     nan     nan     nan
                140     98      103     86      97      80      93      74      85      nan     nan     nan     nan
                145     103     108     91      102     85      98      79      90      nan     nan     nan     nan
                150     108     113     96      107     90      103     84      95      76      89      nan     nan
                155     113     118     101     112     95      108     89      100     81      94      nan     nan
                160     118     123     106     117     100     113     94      105     86      99      nan     nan
                165     123     128     111     122     105     118     99      110     91      104     nan     nan
                170     128     133     116     127     110     123     104     115     96      109     nan     nan
                175     133     138     121     132     115     128     109     120     101     114     nan     nan
                180     138     143     126     137     120     133     114     125     106     119     80      110
                185     143     148     131     142     125     137     119     130     111     123     nan     nan
                190     148     153     136     147     130     142     124     135     116     128     nan     nan
                195     153     158     141     152     135     147     129     140     121     133     nan     nan
                200     158     163     146     157     140     152     134     145     126     138     100     130
                205     163     168     151     162     145     157     139     150     131     143     nan     nan
                210     168     173     156     167     150     162     144     155     136     148     nan     nan
                215     173     178     161     172     155     167     149     160     141     153     nan     nan
                220     178     183     166     177     160     172     154     165     146     158     120     150
                225     183     188     171     182     165     177     159     170     151     163     nan     nan
                230     188     193     176     187     170     182     164     175     156     168     nan     nan
                235     193     198     181     192     175     187     169     180     161     173     nan     nan
                240     198     203     186     197     180     192     174     185     166     178     140     170
                245     203     208     191     202     185     197     179     190     171     183     nan     nan
                250     208     213     196     207     190     202     184     195     176     188     nan     nan
                255     213     218     201     212     195     207     189     200     181     193     nan     nan
                260     218     223     206     217     200     212     194     205     186     198     160     190
                265     223     228     211     222     205     217     199     210     191     203     nan     nan
                270     228     233     216     227     210     222     204     215     196     208     nan     nan
                275     233     238     221     232     215     227     209     220     201     213     nan     nan
                280     238     243     226     237     220     232     214     225     206     218     180     210
                285     243     248     231     242     225     237     219     230     211     223     nan     nan
                290     248     253     236     247     230     242     224     235     216     228     nan     nan
                295     253     258     241     252     235     247     229     240     221     233     nan     nan
                300     258     263     246     257     240     252     234     245     226     238     200     230
                305     nan     nan     251     262     245     257     239     250     231     243     nan     nan
                310     nan     nan     256     267     250     262     244     255     236     248     nan     nan
                315     nan     nan     261     272     255     267     249     260     241     253     nan     nan
                320     nan     nan     266     276     260     272     254     264     246     258     220     250
                325     nan     nan     271     281     265     277     259     269     251     263     nan     nan
                330     nan     nan     276     286     270     282     264     274     256     268     nan     nan
                335     nan     nan     281     291     275     287     269     279     261     273     nan     nan
                340     nan     nan     286     296     280     292     274     284     266     278     240     270
                345     nan     nan     291     301     285     297     279     289     271     283     nan     nan
                350     nan     nan     296     306     290     302     284     294     276     288     nan     nan
                355     nan     nan     301     311     295     307     289     299     281     293     nan     nan
                360     nan     nan     306     316     300     312     294     304     286     298     260     290
                365     nan     nan     311     321     305     317     299     309     291     303     nan     nan
                370     nan     nan     316     326     310     322     304     314     296     308     nan     nan
                375     nan     nan     321     331     315     327     309     319     301     313     nan     nan
                380     nan     nan     326     336     320     332     314     324     306     318     280     310
                385     nan     nan     331     341     325     337     319     329     311     323     nan     nan
                390     nan     nan     336     346     330     342     324     334     316     328     nan     nan
                395     nan     nan     341     351     335     347     329     339     321     333     nan     nan
                400     nan     nan     346     356     340     352     334     344     326     338     300     330
                405     nan     nan     351     361     345     356     339     349     331     342     nan     nan
                410     nan     nan     356     366     350     361     344     354     336     347     nan     nan
                415     nan     nan     361     371     355     366     349     359     341     352     nan     nan
                420     nan     nan     366     376     360     371     354     364     346     357     320     350
                425     nan     nan     371     381     365     376     359     369     351     362     nan     nan
                430     nan     nan     376     386     370     381     364     374     356     367     nan     nan
                435     nan     nan     381     391     375     386     369     379     361     372     nan     nan
                440     nan     nan     386     396     380     391     374     384     366     377     340     370
                445     nan     nan     391     401     385     396     379     389     371     382     nan     nan
                450     nan     nan     396     406     390     401     384     394     376     387     nan     nan
                455     nan     nan     401     411     395     406     389     399     381     392     nan     nan
                460     nan     nan     406     416     400     411     394     404     386     397     360     390
                465     nan     nan     411     421     405     416     399     409     391     402     nan     nan
                470     nan     nan     416     426     410     421     404     414     396     407     nan     nan
                475     nan     nan     421     431     415     426     409     419     401     412     nan     nan
                480     nan     nan     426     436     420     431     414     424     406     417     380     410
                485     nan     nan     431     441     425     436     419     429     411     422     nan     nan
                490     nan     nan     436     446     430     441     424     434     416     427     nan     nan
                495     nan     nan     441     451     435     446     429     439     421     432     nan     nan
                500     nan     nan     446     456     440     451     434     444     426     437     400     430];
        end

        function table = get_dast3a_data_for_bolt_size(boltSize)
            arguments
                boltSize string
            end
            usain.fastener.DastHvLengthData.is_valid_bolt_size(boltSize);

            % Based on size get sub-set of the full data, also remove NaNs such that you end up with valid lengths only.
            thisSizeColumnId = find(contains(usain.fastener.DastHvLengthData.BOLT_OPTIONS_ORDER, boltSize));
            columns = [1, 2 * thisSizeColumnId, 2 * thisSizeColumnId + 1];

            allData = usain.fastener.DastHvLengthData.get_dast3a_table();
            table = allData(:, columns);
            hasNan = isnan(table(:, 2));
            table(hasNan, :) = [];
        end

        function boltLength = query_bolt_length(boltSize, clampedLength)
            arguments
                boltSize string
                clampedLength (:, 1) double
            end
            % Determine the bolt length based on the clamped length.
            % When the clamped length would allow for multiple bolt length options, it is prefferd to pick the length
            % which is not at the edges of the clampedLength range.

            boltLength = nan(size(clampedLength));
            dataTable = usain.fastener.DastHvLengthData.get_dast3a_data_for_bolt_size(boltSize);

            for iClampedLength = 1:numel(clampedLength)
                thisClampedLength = round(clampedLength(iClampedLength), 4, 'significant');

                isInRange = thisClampedLength >= dataTable(:, 2) & thisClampedLength <= dataTable(:, 3);

                if any(isInRange)
                    dataSubSet = dataTable(isInRange, :);

                    distToMin = thisClampedLength - dataSubSet(:, 2);
                    distToMax = dataSubSet(:, 3) - thisClampedLength;

                    differenceInDistance = abs(diff([distToMax, distToMin], 1, 2));
                    [~, id] = min(differenceInDistance);

                    boltLength(iClampedLength, 1) = round(dataSubSet(id, 1), 4, 'significant');
                end
            end

        end

        function [pass, msg] = is_valid_bolt_size(boltSize)
            pass = any(ismember(usain.fastener.DastHvLengthData.BOLT_OPTIONS_ORDER, boltSize));
            msg = '';
            if ~pass
                msg = 'Only data for bolt sizes according to DASt Ri 021 Table 3a is available.';
                error('DastHvLengthData:invalidBoltSize', msg);
            end

        end

    end

end
