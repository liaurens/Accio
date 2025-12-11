classdef calc_contact_diameter_Test < Unittest.TestCase  % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function calc_contact_diameter__inputs_not_same_length(Obj)
            % GIVEN inputs of different lengths
            diamNut = ones(1, 5);
            diamWasher = ones(1, 5);
            lenWasher = ones(1, 3);

            % WHEN THEN
            f = @() usain.fastener.calc_contact_diameter(diamNut, diamWasher, lenWasher);
            Obj.assertError(f, 'calc_contact_diameter:InputNotSameLength');
        end

        function calc_contact_diameter__happy(Obj)
            % GIVEN
            diamNut = 1.1 * ones(1, 5);
            diamWasher = 1.2 * ones(1, 5);

            % WHEN all washer lenghts are 0mm
            % THEN
            actual = usain.fastener.calc_contact_diameter(diamNut, diamWasher, zeros(1, 5));
            expected = diamNut;
            Obj.assertEqual(actual, expected);

            % WHEN all washer lenghts are >0mm
            % THEN
            actual = usain.fastener.calc_contact_diameter(diamNut, diamWasher, ones(1, 5));
            expected = diamWasher;
            Obj.assertEqual(actual, expected);

            % WHEN some washer lenghts are 0mm and some are >0mm
            % THEN
            actual = usain.fastener.calc_contact_diameter(diamNut, diamWasher, [0, 0, 1, 1, 0]);
            expected = [1.1, 1.1, 1.2, 1.2, 1.1];
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-6);
        end

    end
end
