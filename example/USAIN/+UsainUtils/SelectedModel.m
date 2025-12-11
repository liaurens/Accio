classdef SelectedModel < UsainUtils.FlangeModel
    % CLASSNAME Summary of this class goes here
    %   Detailed explanation goes here

    % TODO Write help doc

    properties
    end

    methods

        function Obj = SelectedModel(varargin)

            % Pass inputs on to superclass constructor
            Obj@UsainUtils.FlangeModel(varargin{:});
        end

    end

    methods (Static)

        function Obj = select_flange_model(FlnMdl, iSel)

            assert(isscalar(iSel), 'USAIN:SelectedModel:NonScalar', "iSel argument is not scalar");

            FlnMdl.info('Rebuilding model for selected design.');

            % Get input properties pertaining to selected design point
            Best = FlnMdl.select_design_points(iSel);

            % Update inputs struct to limit width, thickness and number of bolts
            % to just the selected design
            [Best.Inputs.minFlangeWidth, Best.Inputs.maxFlangeWidth] = deal(FlnMdl.Space.width(iSel));
            [Best.Inputs.minFlangeThickn, Best.Inputs.maxFlangeThickn] = deal(FlnMdl.Space.thickness(iSel));
            [Best.Inputs.minNBolts, Best.Inputs.maxNBolts] = deal(FlnMdl.Space.nBolts(iSel));

            % Set other parameters
            Best.Inputs.lengthBoltExtender = FlnMdl.Extr.len(iSel);
            Best.Inputs.boltOptions = {usain.fastener.BoltSpecificationString( ...
                char(FlnMdl.Bolt.label(iSel)), ...
                FlnMdl.Bolt.len(iSel), ...
                FlnMdl.Bolt.lenThread(iSel)).specification};

            % Construct FlangeModel object for selected design point
            mdlArgs = cellfun(@(x) {x; Best.(x)}, fieldnames(Best), 'uni', 0);
            mdlArgs = cat(1, mdlArgs{:})';
            Obj = UsainUtils.SelectedModel.setup_obj(mdlArgs{:});
        end

        function Obj = setup_obj(varargin)
            % NOTE: Overloads superclass method

            Obj = UsainUtils.SelectedModel(varargin{:});
            Obj.prepare_obj_for_operation();
        end

    end
end
