classdef ExtenderData < usain.fastener.BaseCatalogData

    properties
        label char
        diamIn double  % Inner diameter
        diamOut double  % Outer diameter
        maxAllowedLength double  % Maximum allowed length (generally 2*d_b)
        len double = nan  % Nominal length of bolt extender
    end
    properties (Constant)
        REQUIRED_FIELDS = {'label', 'diamIn', 'diamOut', 'maxAllowedLength'}
        EXPORT_FIELDS = {'label', 'diamIn', 'diamOut', 'len'}

        MIN_LEN = 10e-3  % Minimum extender length [m]
    end

    methods

        function validate(Obj)
            Validator = usain.fastener.CatalogDataValidator('extender');
            for iObj = 1:length(Obj)
                This = Obj(iObj);

                % Expect diamIn < diamOut
                Validator.validate(@() assert(This.diamIn <= This.diamOut, ...
                    '%-10s: expected inner diameter <= outer diameter', This.label));
            end
            Validator.report();
        end

    end

    methods (Static)

        function Objs = from_struct(S)
            % See usain.fastener.BaseCatalogData.from_struct

            assert(isfield(S, 'data'), 'ExtenderData:from_struct:InvalidStruct', ...
                'Expected struct with "data" field.');

            nInputSets = length(S.data);
            Objs(nInputSets, 1) = usain.fastener.ExtenderData();
            for iInp = 1:nInputSets
                Objs(iInp) = usain.fastener.ExtenderData(S.data(iInp));
            end
        end

        function length = get_length_options(lengthFromInputs, label, stepSize)
            % Returns array with extender length options
            %
            % lengthFromInputs: Input value `lengthBoltExtender`
            % label: Fastener label, e.g. 'ISO_M42'
            % stepSize: Step size in bolt extender lengths

            if isnan(lengthFromInputs)
                % No input was provided, return all standard lengths
                Lib = usain.fastener.CatalogLibrary.get_library();
                Extender = Lib.Extenders.select('label', label);
                length = [0, (Extender.MIN_LEN:stepSize:Extender.maxAllowedLength)];
            else
                % Return what user provided as input
                length = lengthFromInputs;
            end
        end

        function assertFn = validate_extender_length(len, label)
            % Check if input extender length(s) is/are valid
            %
            % extenderLength: (Array of) extender lengths
            % label: Bolt label(s) as cellstr, e.g. {'HV_M72', 'ISO_M42'}

            msg = {};
            Lib = usain.fastener.CatalogLibrary.get_library();
            for iOpt = 1:length(label)

                % Only do this check if a nonzero extender length is input
                if len(iOpt) <= 1e-6
                    continue
                end

                % First capture message for an extender length that is too long, because the max length may be
                % < the min length (e.g. for ISO_M80 or JIS the max length is 0mm, while the min length is always
                % 10mm)
                Ext = Lib.Extenders.select('label', label{iOpt});
                if len(iOpt) > Ext.maxAllowedLength
                    msg{end + 1} = sprintf('Extender length for %s must be <= %.1fmm.', ...
                        label{iOpt}, 1e3 * Ext.maxAllowedLength); %#ok
                    continue
                end
                if len(iOpt) < Ext.MIN_LEN
                    msg{end + 1} = sprintf('Extender length for %s must be >= %.1fmm.', ...
                        label{iOpt}, 1e3 * Ext.MIN_LEN); %#ok
                end
            end

            % Throw all error messages at once
            errId = 'ExtenderData:validate_extender_length:ValidationError';
            assertFn = @() assert(isempty(msg), errId, '%s', strjoin(msg, '\n\n'));
            if ~nargout
                assertFn();
            end
        end

        function mass = calc_mass(diamOut, diamIn, len)
            % Computes extender mass
            % Mass is not a property of this class, because USAIN sets the bolt extender length only after
            % this dataclass is converted to static data types.
            rho = 7850;
            mass = pi .* rho .* len .* ((diamOut ./ 2).^2 - (diamIn ./ 2).^2);
        end

    end
end
