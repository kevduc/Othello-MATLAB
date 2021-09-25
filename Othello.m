classdef Othello < handle
%OTHELLO Launch Othello game
%   OTHELLO() starts a 2-player local game (shared-mouse)
%   OTHELLO(boardSize) boardsize should be a 2x1 vector, and
%   more than [2 2]
%   OTHELLO(opponent) starts a 2-player online game
%   opponent is the opponent's computer IP address
%   OTHELLO(opponent, yourColor) yourColor can be 'w' or 'b'
%   OTHELLO(opponent, boardSize)
%   OTHELLO(opponent, yourColor, boardSize)
    properties (Access = private, Constant)
        DefaultBoardSize = [8 8];
        PlayersFgColor = ['k','w'];
        PlayersBgColor = ['w','k'];
        role2player = containers.Map({'server', 'client'}, {char(Player.White), char(Player.Black)});
        player2role = containers.Map({char(Player.White), char(Player.Black)}, {'server', 'client'});
    end
    properties (Access = private)
        board
        sys
        net
        gui
        clickListener
        message
        messageTimer
        localPlayer
        online
        opponent
        opponentClickListener
        opponentStatusListener
        gameEnded
    end
    events
        GameClosed
    end
    
    properties (SetAccess = private, GetAccess = public)
    end
    
    methods
        function obj = Othello(varargin)
            boardSize = Othello.DefaultBoardSize;
            obj.opponent = '';
            obj.online = false;
            obj.localPlayer = Player.None;
            
            if nargin == 1
                if ischar(varargin{1})
                    obj.opponent = varargin{1};
                    obj.online = true;
                else
                    boardSize = varargin{1};
                end
            elseif nargin == 2
                obj.opponent = varargin{1};
                obj.online = true;
                if ischar(varargin{2})
                    obj.localPlayer = Player(varargin{2});
                else
                    boardSize = varargin{2};
                end
            elseif nargin > 3
                error('Too many inputs arguments');
            end
            
            assert(any(boardSize > 2), 'The size of the board needs to be more than 2x2!');
            obj.opponent = lower(obj.opponent);

            obj.gui = OthelloGUI(boardSize, @(src,evt)obj.delete);
            obj.board = OthelloBoard(boardSize);
            obj.sys = OthelloSYS(obj.board);
            obj.message = struct('string', '', 'fgColor', 'k', 'bgColor', [1 1 1]*.65);
            obj.messageTimer = timer('StartDelay', 1, 'TimerFcn', @(src,evt)obj.guiMessageUpdate);
            
            addlistener(obj.board,'Updated',@(src,evt)obj.guiBoardUpdate);
            addlistener(obj.sys,'scores','PostSet',@(src,evt)obj.guiScoresUpdate);
            addlistener(obj.sys,'currentPlayer','PostSet',@(src,evt)obj.dispPlayersTurn);
            addlistener(obj.sys,'CannotPlay',@(src,evt)obj.dispErrorMessage([char(obj.sys.currentPlayer) ' cannot play!']));
            
            if obj.online
                obj.net = OthelloNET(obj.opponent);
                obj.opponentStatusListener = addlistener(obj.net,'opponentStatus','PostSet',@(src,evt)obj.opponentStatusHandler);
            end
            
            start(timer('StartDelay', 0, 'TimerFcn', @(src,evt)obj.start()));
        end
        
        function delete(obj)
            delete(obj.messageTimer);
            delete(obj.sys);
            delete(obj.board);
            delete(obj.gui);
            if obj.online
                if strcmp(obj.net.connection.Status,'open')
                    obj.net.sendStatus('closed');
                end
                delete(obj.net);
            end
            notify(obj,'GameClosed');
        end
    end
    
    methods (Access = private)
        function start(obj)
            if obj.online
                obj.dispMessage(['Connecting to ' obj.opponent '...'], 'w', [236 176 0]/255);
                if obj.localPlayer == Player.None
                    obj.net.connect();
                else
                    obj.net.connect(obj.player2role(char(obj.localPlayer)));
                end
                obj.dispMessage(['Connected to ' obj.opponent], 'w', [16 167 23]/255);
                
                if obj.localPlayer == Player.None
                    obj.localPlayer = Player(obj.role2player(obj.net.connection.NetworkRole));
                end
                obj.gui.setLabel(obj.localPlayer, 'You');
                
                pause(1);
            end
            
            obj.sys.initialize();
            obj.gameEnded = false;
                        
            obj.clickListener = addlistener(obj.gui,'Click',@(src,evt)obj.clickHandler);
            if obj.online
                obj.opponentClickListener = addlistener(obj.net,'CoordsReceived',@(src,evt)obj.opponentClickHandler);
            end
            
            addlistener(obj.sys,'GameEnd',@(src,evt)obj.dispWinner);
        end
        
        function clickHandler(obj)
            if obj.online && (obj.sys.currentPlayer ~= obj.localPlayer)
                obj.dispErrorMessage('Not your turn!');
                return;
            end
            coords = obj.gui.clickedCell;
            err = obj.sys.play(coords(1),coords(2));
                    if obj.online
                        obj.net.send(coords);
                    end
            switch err
                %case InvalidMove.None
                case InvalidMove.CellOccupied
                    obj.dispErrorMessage('Cell Occupied');
                case InvalidMove.NoFlipping
                    obj.dispErrorMessage('Nothing to take!');
                case InvalidMove.OutOfBound
                    obj.dispErrorMessage('Out of bound!');
            end
        end
        
        function opponentClickHandler(obj)
            coords = obj.net.receivedCoords;
            err = obj.sys.play(coords(1),coords(2));
            if err ~= InvalidMove.None
                obj.dispErrorMessage([char(obj.sys.currentPlayer) ' doesn''t seem to know the rules...']);
            end
        end
        
        function opponentStatusHandler(obj)
            switch obj.net.opponentStatus
                case 'notstarted'
                    obj.dispMessage(['Waiting for ' obj.opponent ' to connect...'], 'w', [236 176 0]/255);
                case 'closed'
                    obj.disableAll();
                    obj.setMessage([char(obj.localPlayer.next()) ' left the game'], 'w', [197 25 41]/255);
                    obj.guiMessageUpdate();
            end
        end
        
        function disableAll(obj)
            delete(obj.clickListener);
            delete(obj.opponentClickListener);
            delete(obj.opponentStatusListener);
        end
        
        function dispWinner(obj)
            obj.disableAll();
            player = find(obj.sys.scores == max(obj.sys.scores));
            if size(player,2) == 1
                obj.setMessage([char(Player(player)) ' Wins! \o/'], ...
                    obj.PlayersFgColor(player), ...
                    obj.PlayersBgColor(player));
            else
                obj.setMessage('Draw!', [1 1 1]*.30, [1 1 1]*.94);
            end
            obj.guiMessageUpdate();
            obj.gameEnded = true;
        end
        
        function dispPlayersTurn(obj)
            obj.setMessage([char(obj.sys.currentPlayer) '''s turn'], ...
                obj.PlayersFgColor(obj.sys.currentPlayer), ...
                obj.PlayersBgColor(obj.sys.currentPlayer));
            obj.guiMessageUpdate();
        end
        
        function dispMessage(obj, msg, fgColor, bgColor)
            obj.gui.dispMessage(msg);
            obj.gui.setMessageColor(fgColor, bgColor);
            drawnow;
        end
        
        function dispErrorMessage(obj, errMsg)
            obj.gui.dispMessage(errMsg);
            obj.gui.setMessageColor('r',[1 1 1]*.94);
            stop(obj.messageTimer);
            start(obj.messageTimer);
        end
        
        function setMessage(obj, msg, fgColor, bgColor)
            obj.message.string = msg;
            obj.message.fgColor = fgColor;
            obj.message.bgColor = bgColor;
        end
        
        function guiMessageUpdate(obj)
            obj.gui.dispMessage(obj.message.string);
            obj.gui.setMessageColor(obj.message.fgColor, obj.message.bgColor);
        end
            
        function guiScoresUpdate(obj)
            obj.guiScoreUpdate(Player.White);
            obj.guiScoreUpdate(Player.Black);
        end
        
        function guiBoardUpdate(obj)
            obj.guiTokensUpdate(Player.White);
            obj.guiTokensUpdate(Player.Black);
        end
    end
    
    methods (Access = private)
        function guiScoreUpdate(obj, player)
            obj.gui.dispScore(player, obj.sys.scores(player));
        end
        
        function guiTokensUpdate(obj, player)
            [rows, cols] = obj.board.getTokensPos(player);
            obj.gui.plotTokens(rows, cols, player);
        end
    end
end

