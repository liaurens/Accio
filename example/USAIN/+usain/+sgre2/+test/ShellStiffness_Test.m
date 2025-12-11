classdef ShellStiffness_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function create__expected(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyClass(usain.sgre2.ShellStiffness.create("simplified"), 'usain.sgre2.SimplifiedShellStiffness');
            Obj.verifyClass(usain.sgre2.ShellStiffness.create("interpolated"), 'usain.sgre2.InterpolatedShellStiffness');  % mh:ignore_style

            Obj.verifyError(@() usain.sgre2.ShellStiffness.create("foo"), 'ShellStiffness:UnsupportedMethod');
        end

    end
end
