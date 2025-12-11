classdef Petersen_Test < UsainTest.UsainTestCase

    properties
        TestObj
    end
    properties (TestParameter)
        % Lower and upper values chosen to ensure evaluation of Petersen
        % in both "segments"
        fApplied    = struct('small', 100,  'representative', 750e3, 'alsorepresentative', 1200e3, 'large', 99e9)

        % Expected outcomes
        fBoltExpect = struct('small', 1.6800e6, 'representative', 1.9669e6, 'alsorepresentative', 2.2952e6, 'large', 1.8936e11) % mh:ignore_style
    end

    methods (TestMethodSetup)

        function init_test_object(Obj)
            Obj.TestObj = UsainUtils.Petersen();
            Obj.TestObj.Logger.abortOnError = true;

            Obj.set_test_input_data();
        end

    end

    methods (Test, ParameterCombination = 'sequential', TestTags = {'unit'})

        function get_bolt_force__happy(Obj, fApplied, fBoltExpect)
            % GIVEN the test parameters provided to this method
            % WHEN, THEN
            forceBolt = Obj.TestObj.get_bolt_force(fApplied);
            expected = fBoltExpect;
            Obj.assertEqual(forceBolt, expected, 'RelTol', 1e-4);
        end

        function get_intermediate_results__happy(Obj)
            % GIVEN, WHEN, THEN
            actual = Obj.TestObj.get_intermediate_results();
            expected = { ...
                'Applied bolt force model     |       petersen'
                'Load factor                  |          0.200'
                'Knee point, Zcr              |           1098kN'
                'Preload                      |           1680kN'
                };
            Obj.assertEqual(actual, expected);
        end

    end

    methods

        function set_test_input_data(Obj)
            Obj.TestObj = UsainUtils.Petersen( ...
                'preload', 1680e3, ...
                'loadFactor', 0.2, ...
                'lambda', 1.9127, ...
                'zCr', 1.0979e6);
        end

    end
end
