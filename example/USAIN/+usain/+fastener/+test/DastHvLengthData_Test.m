classdef DastHvLengthData_Test < Unittest.TestCase

    properties (TestParameter)
        boltSizes = cellstr(usain.fastener.DastHvLengthData.BOLT_OPTIONS_ORDER)
    end

    methods (Test, TestTags = {'unit'})

        function get_dast3a_table__happy(Obj)
            % GIVEN WHEN THEN
            actual = usain.fastener.DastHvLengthData.get_dast3a_table();
            Obj.assertSize(actual, [84, 13]);
        end

        function get_dast3a_data_for_bolt_size__happy(Obj, boltSizes)
            % GIVEN WHEN
            actual = usain.fastener.DastHvLengthData.get_dast3a_data_for_bolt_size(string(boltSizes));

            % THEN expect that you always have 3 columns and all contains actual data, i.e. not NaN.
            [~, nCol] = size(actual);
            Obj.verifyEqual(nCol, 3);
            Obj.verifyTrue(all(all(~isnan(actual))));
        end

        function querry_bolt_length__happy(Obj)
            % GIVEN some samples of the DASt3a table, which exceed the table, are at the edge and would cover multiple
            % allowed bolt lengths.
            boltSize = "M56";
            clampedLength = 1e-3 * [60; 74; 90; 444; 450];

            % WHEN
            actual = usain.fastener.DastHvLengthData.query_bolt_length(boltSize, clampedLength);

            % THEN
            expected = 1e-3 * [nan; 140; 150; 500; nan];
            Obj.assertEqual(actual, expected);
        end

        function is_valid_bolt_size__happy(Obj, boltSizes)
            % GIVEN valid bolt sizes
            % WHEN THEN
            Obj.temp_suppress_warning('MATLAB:subscripting:noSubscriptsSpecified');
            Obj.verify_error_free(usain.fastener.DastHvLengthData.get_dast3a_data_for_bolt_size(string(boltSizes)));
        end

        function is_valid_bolt_size__sad(Obj)
            % GIVEN an invalid bolt size
            boltSize = "M80";

            expectedMsg = 'Only data for bolt sizes according to DASt Ri 021 Table 3a is available.';
            Obj.assertRaisesMessageRegex(@() ...
                usain.fastener.DastHvLengthData.get_dast3a_data_for_bolt_size(boltSize), expectedMsg);
        end

    end

end
