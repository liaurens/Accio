classdef SchmidtNeuper_Test < UsainTest.UsainTestCase

    properties
        TestObj
    end
    properties (TestParameter)
        % Lower and upper values chosen to ensure evaluation of Schmidt-Neuper
        % in first and third "segment"
        fApplied    = struct('small', 100,  'representative', 750e3, 'large', 99e9)

        % Expected outcomes, benchmarked at 2018-06-06
        fBoltExpect = struct('small', 1.6800e6, 'representative', 1.8562e6, 'large', 1.8936e11)
    end

    methods (TestMethodSetup)

        function init_test_object(Obj)
            Obj.TestObj = UsainUtils.SchmidtNeuper();
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

        function get_bolt_force__mex_same_as_matlab_implementation(Obj, fApplied)
            % GIVEN data for matlab method call
            preload = Obj.TestObj.preload;
            p = Obj.TestObj.loadFactor;
            lambda = Obj.TestObj.lambda;
            z1 = Obj.TestObj.z1;
            z2 = Obj.TestObj.z2;

            % WHEN
            actualMex = Obj.TestObj.get_bolt_force(fApplied);
            actualMatlab = Obj.TestObj.get_bolt_force_m(preload, p, lambda, z1, z2, fApplied);
            Obj.assertEqual(actualMex, actualMatlab, 'RelTol', 1e-6);
        end

        function get_intermediate_results__happy(Obj)
            % GIVEN, WHEN, THEN
            actual = Obj.TestObj.get_intermediate_results();
            expected = { ...
                'Applied bolt force model     |  schmidtneuper'
                'Load factor                  |          0.200'
                'Knee point, Z1               |            698kN'
                'Knee point, Z2               |           1098kN'
                'Preload                      |           1680kN'
                };
            Obj.assertEqual(actual, expected);
        end

    end

    methods

        function set_test_input_data(Obj)
            Obj.TestObj = UsainUtils.SchmidtNeuper( ...
                'preload', 1680e3, ...
                'loadFactor', 0.2, ...
                'lambda', 1.9127, ...
                'z1', 6.9763e5, ...
                'z2', 1.0979e6);
        end

    end
end
