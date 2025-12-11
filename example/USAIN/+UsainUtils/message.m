function varargout = message()
    % MESSAGE Returns or prints USAIN welcome message (ASCII art)
    %
    % SYNTAX:
    % - *msg = UsainUtils.message()
    %       * = optional
    %
    % OUTPUTS:
    % - msg: [cell] (optional) Cell of strings containig welcome message
    %
    % NOTES:
    % - If no output arguments are used in the function call, the message will
    %   be directly printed to the Command Window. Otherwise, the message will
    %   be returned in output 'msg'.
    %
    % SEE ALSO:
    % - USAIN
    %
    % =============================================================
    %

    % Hard-code run lanes
    nLanes = 2;
    iLaneStart = [4 10];
    runLanes = { ...
      ''
      '_____________________________________________________________                                                '  % mh:ignore_style
      '     |                                                       |                                               '  % mh:ignore_style
      ' /|  |                                                       |     ##     ##  ######     ###     ##  ##    ##'  % mh:ignore_style
      '  |  |                                                       |     ##     ## ##    ##   ## ##   #### ###   ##'  % mh:ignore_style
      ' _|_ |                                                       |     ##     ## ##        ##   ##  #### ####  ##'  % mh:ignore_style
      '     |                                                       |     ##     ##  ######  ##     ##  ##  ## ## ##'  % mh:ignore_style
      '_____|_______________________________________________________|     ##     ##       ## #########  ##  ##  ####'  % mh:ignore_style
      '     |                                                       |     ##     ## ##    ## ##     ## #### ##   ###'  % mh:ignore_style
      ' __  |                                                       |      #######   ######  ##     ## #### ##    ##'  % mh:ignore_style
      ' __| |                                                       |                                               '  % mh:ignore_style
      '|__  |                                                       |                        User interface for Stub'  % mh:ignore_style
      '     |                                                       |                   Assemblies with Immense Nuts'  % mh:ignore_style
      ['_____|_______________________________________________________|  ' sprintf('%45s', USAIN.VERSION)]
      ''};

    % Hard-code running stickman snapshots
    stickMan = cell(0);
    stickMan{end + 1} = { ...
        ' _ O'
        '\ /v'
        ' v\ '
        '   \'};
    stickMan{end + 1} = { ...
        ' __O'
        '  /\'
        '_/\ '
        '  / '};
    stickMan{end + 1} = { ...
        ' __O'
        '  /\'
        ' v\ '
        '  / '};
    stickMan{end + 1} = { ...
        ' _ O'
        '  /v'
        ' /-_'
        '/   '};
    nAnim = numel(stickMan);
    szMan = size(stickMan{1}{1}, 2);

    % Randomly pick initial posture of runners
    rng('shuffle');
    initPos = randi([1 nAnim], [1 nLanes]);

    % Define progress counters for the individual runners
    iProgress = ones(1, nLanes);
    iPrint = 1;
    maxProgress = regexp(runLanes{2}, '\s', 'once') - szMan;
    while all(iProgress < maxProgress)

        % Copy runLane ascii template
        thisLanes = runLanes;

        % Update run lane text with runners' progress
        for iLane = 1:nLanes
            thisRunner = stickMan{1 + mod(initPos(iLane) + iPrint, nAnim)};
            iProgress(iLane) = min(iProgress(iLane) + randi([1 6]), maxProgress);
            printCell = arrayfun(@(i) ...
                sprintf(repmat('%s', 1, size(thisRunner, 2)), thisRunner{i, :}), ...
                1:size(thisRunner, 1), 'uni', 0);

            for iMod = 1:4
                iLn = iLaneStart(iLane) - 1 + iMod;
                modLine = thisLanes{iLn};
                thisLanes{iLn} = [modLine(1:iProgress(iLane)), ...
                    printCell{iMod}, ...
                    modLine(iProgress(iLane) + length(printCell{iMod}) + 1:end)];
            end
        end

        % Format text to print to screen
        printCell = arrayfun(@(i) ...
            sprintf([repmat('%s', 1, size(thisLanes, 2)), '\n'], thisLanes{i, :}), ...
            1:size(thisLanes, 1), 'uni', 0);
        printStr = [printCell{:}];
        clearFmt = repmat('\b', 1, numel(printStr));
        if iPrint == 1
            clearFmt = '';
        end

        % Print, pause and update counter
        fprintf([clearFmt, '%s'], printStr);
        pause(0.02);
        iPrint = iPrint + 1;
    end

    % Prepare return argument (for logging static ASCII art)
    if nargout
        varargout{1} = regexprep(printStr, '\\', '\\\\');
    end
