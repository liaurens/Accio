classdef EquivalentScfData_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function merge_and_sort__happy(Obj)
            % GIVEN
            EqvScf1 = usain.io.EquivalentScfData( ...
                labels = ["FL03", "FL02"], ...
                bendingScfInside = [1.2 1.1], ...
                bendingScfOutside = [1.4 1.3]);
            EqvScf2 = usain.io.EquivalentScfData( ...
                labels = "FL01", ...
                bendingScfInside = 2.1, ...
                bendingScfOutside = 2.3);

            % WHEN
            Actual = usain.io.EquivalentScfData.merge_and_sort(EqvScf1, EqvScf2);

            % THEN
            Obj.verifyClass(Actual, 'usain.io.EquivalentScfData');
            Obj.verifyEqual(Actual.labels, ["FL01", "FL02", "FL03"]);
            Obj.verifyEqual(Actual.bendingScfInside, [2.1 1.1 1.2]);
            Obj.verifyEqual(Actual.bendingScfOutside, [2.3 1.3 1.4]);
        end

        function merge_and_sort__empty_object(Obj)
            % GIVEN
            EqvScf1 = usain.io.EquivalentScfData( ...
                labels = ["FL02", "FL03"], ...
                bendingScfInside = [1.1 1.2], ...
                bendingScfOutside = [1.3 1.4]);
            EqvScf2 = usain.io.EquivalentScfData( ...
                labels = ["FL01"], ...
                bendingScfInside = [2.1], ...
                bendingScfOutside = [2.3]);
            EqvScf3 = usain.io.EquivalentScfData.empty;

            % WHEN
            Actual = usain.io.EquivalentScfData.merge_and_sort(EqvScf1, EqvScf2, EqvScf3);

            % THEN
            Obj.verifyClass(Actual, 'usain.io.EquivalentScfData');
            Obj.verifyEqual(Actual.labels, ["FL01", "FL02", "FL03"]);
            Obj.verifyEqual(Actual.bendingScfInside, [2.1 1.1 1.2]);
            Obj.verifyEqual(Actual.bendingScfOutside, [2.3 1.3 1.4]);
        end

        function merge_and_sort__single_object(Obj)
            % GIVEN
            EqvScf1 = usain.io.EquivalentScfData( ...
                labels = ["FL02", "FL03"], ...
                bendingScfInside = [1.1 1.2], ...
                bendingScfOutside = [1.3 1.4]);

            % WHEN
            Actual = usain.io.EquivalentScfData.merge_and_sort(EqvScf1);

            % THEN
            Obj.verifyClass(Actual, 'usain.io.EquivalentScfData');
            Obj.verifyEqual(Actual.labels, EqvScf1.labels);
            Obj.verifyEqual(Actual.bendingScfInside, EqvScf1.bendingScfInside);
            Obj.verifyEqual(Actual.bendingScfOutside, EqvScf1.bendingScfOutside);
        end

        function to_struct__happy(Obj)
            % GIVEN
            EqvScf = usain.io.EquivalentScfData( ...
                labels = ["FL02", "FL03"], ...
                bendingScfInside = [1.1 1.2], ...
                bendingScfOutside = [1.3 1.4]);

            % WHEN, THEN
            S = EqvScf.to_struct();
            Obj.verifyClass(S, 'struct');
            Obj.verifyTrue(isfield(S, 'labels'));
            Obj.verifyTrue(isfield(S, 'bendingScfInside'));
            Obj.verifyTrue(isfield(S, 'bendingScfOutside'));
        end

        function constructor__happy_from_struct(Obj)
            % GIVEN
            S = struct( ...
                'labels', ["FL02", "FL03"], ...
                'bendingScfInside', [1.1 1.2], ...
                'bendingScfOutside', [1.3 1.4]);

            % WHEN, THEN
            Actual = usain.io.EquivalentScfData(S);
            Obj.verifyClass(Actual, 'usain.io.EquivalentScfData');
            Obj.verifyEqual(Actual.labels, ["FL02", "FL03"]);
            Obj.verifyEqual(Actual.bendingScfInside, [1.1 1.2]);
            Obj.verifyEqual(Actual.bendingScfOutside, [1.3 1.4]);
        end

        function constructor__missing_fields_in_struct(Obj)
            % GIVEN
            S = struct( ...
                'labels', ["FL02", "FL03"], ...
                'bendingScfInside', [1.1 1.2], ...
                'foo', [1.3 1.4]);

            % WHEN, THEN
            Obj.verifyError(@() usain.io.EquivalentScfData(S), ...
                'dataclasses:DataClass:unknownFields');
        end

    end
end
