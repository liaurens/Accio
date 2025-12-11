classdef BoltSpecificationString
    % Bolt specification string, e.g. HV_M42x380 or ISO_M80x600x123
    %
    % The thread length is appended only if the length is non-standard

    properties
        specification char  % Bolt specification string
    end

    methods

        function Obj = BoltSpecificationString(label, lenBolt, lenThread)

            if nargin
                assert(ischar(label), 'label must be char.');
                assert(isnumeric(lenBolt), 'lenBolt must be numeric.');
                assert(isnumeric(lenThread), 'lenThread must be numeric.');

                Obj = Obj.set_specification(label, lenBolt, lenThread);
            end
        end

        function Obj = set_specification(Obj, label, lenBolt, lenThread)

            % Round lengths to nearest micron to avoid engineering notation (e.g. 1.23000e-1) in specification
            lenBolt = round(lenBolt, 6);
            lenThread = round(lenThread, 6);

            labelAndLength = sprintf('%sx%i', label, 1e3 * lenBolt);
            if Obj.is_standard_thread_length(label, lenThread)
                threadSpec = '';
            else
                threadSpec = sprintf('x%i', 1e3 * lenThread);
            end

            Obj.specification = [labelAndLength, threadSpec];
        end

        function bool = is_standard_thread_length(~, label, lenThread)

            standardLength = usain.fastener.FastenerData.get_standard_thread_length(label);
            bool = abs(standardLength - lenThread) < 1e-6;
        end

        function value = char(Obj)
            value = Obj.specification;
        end

    end
end
