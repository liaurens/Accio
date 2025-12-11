classdef ThreadLengthData_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function construction__expected(Obj)
            % GIVEN, WHEN, THEN
            Test = UsainUtils.ThreadLengthData("upper", 0.123);
            Obj.assertEqual(Test.len, 0.123);
            Obj.assertEmpty(Test.utilization);
            Obj.assertEqual(Test.flangeSide, "upper");
        end

        function calc_utilization__only_minimum_length(Obj)
            % GIVEN
            Test = UsainUtils.ThreadLengthData("upper", 0.123);

            % WHEN the minimum length is equal to the actual length
            % THEN
            Test.calc_utilization(0.123);
            Obj.assertEqual(Test.utilization, 1.0);

            % WHEN we double the minimum length
            % THEN
            Test.calc_utilization(0.246);
            Obj.assertEqual(Test.utilization, 2.0);
        end

        function calc_utilization__maximum_governing(Obj)
            % GIVEN
            Test = UsainUtils.ThreadLengthData("upper", 0.100);

            % WHEN we set the feasible limits such that the maximum is driving
            % THEN
            minimum = 0.050;
            maximum = 0.150;
            Test.calc_utilization(minimum, maximum);
            Obj.assertEqual(Test.utilization, 0.6667, 'AbsTol', 1e-4);
        end

        function calc_utilization__minimum_governing(Obj)
            % GIVEN
            Test = UsainUtils.ThreadLengthData("upper", 0.100);

            % WHEN we set the feasible limits such that the minimum is driving
            % THEN
            minimum = 0.050;
            maximum = 0.300;
            Test.calc_utilization(minimum, maximum);
            Obj.assertEqual(Test.utilization, 0.5, 'AbsTol', 1e-4);
        end

        function calc_utilization__negative_length(Obj)
            % GIVEN a negative thread length
            Test = UsainUtils.ThreadLengthData("upper", -0.0123);

            % WHEN, THEN
            Test.calc_utilization(0.01);
            Obj.assertEqual(Test.utilization, 1.0123, 'AbsTol', 1e-4);
        end

        function calc_utilization__zero_length(Obj)
            % GIVEN a zero thread length
            Test = UsainUtils.ThreadLengthData("upper", 0);

            % WHEN, THEN expect an absurdly high utilization ratio
            Test.calc_utilization(0.01);
            Obj.assertGreaterThanOrEqual(Test.utilization, 1e8);

            Test.calc_utilization(0.01, 0.012);
            Obj.assertGreaterThanOrEqual(Test.utilization, 1e8);
        end

        function calc_utilization__length_array(Obj)
            % GIVEN multiple thread lengths
            multiLengths = [-0.0123, 0.100, -0.0123, 0.100, 0.200];
            multiSides = ["upper", "lower", "upper", "upper", "lower"];
            Test = UsainUtils.ThreadLengthData(multiSides, multiLengths);

            % WHEN, THEN
            minimum = 0.050;
            maximum = 0.150;
            Test.calc_utilization(minimum, maximum);
            expected = [1.0123 0.6667, 1.0123, 0.6667, 1.3333];
            Obj.assertSize(Test.utilization, size(multiLengths));
            Obj.assertEqual(Test.utilization, expected, 'AbsTol', 1e-4);
        end

        function zero_utilization_for_hex_bolt__hex_bolt(Obj)
            % GIVEN a hex bolt
            Test = UsainUtils.ThreadLengthData("upper", 0.100);
            Test.utilization = 123;
            fastenerType = 'hex';

            % WHEN
            Test.zero_utilization_for_hex_bolt(fastenerType);
            expected = 0;
            Obj.assertEqual(Test.utilization, expected);
        end

        function zero_utilization_for_hex_bolt__stud_bolt(Obj)
            % GIVEN a stud bolt
            Test = UsainUtils.ThreadLengthData("upper", 0.100);
            Test.utilization = 123;
            fastenerType = 'stud';

            % WHEN
            Test.zero_utilization_for_hex_bolt(fastenerType);
            expected = 123;
            Obj.assertEqual(Test.utilization, expected);
        end

    end

end
