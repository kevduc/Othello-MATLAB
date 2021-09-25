classdef OthelloGUI < handle
    properties (Access = private, Constant)
        DefaultBoardSize = [8 8];
    end
    properties (Access = private)
        boardSize
        fig
        ax
        tokens
        labelScores
        label
        stateBar
    end
    properties (SetAccess = private, GetAccess = public)
        clickedCell
    end
    events
        Click
    end

    methods
        function obj = OthelloGUI(boardSize, onClose)
            if nargin < 2
                onClose = 'closereq';
            end
            if nargin < 1
                boardSize = OthelloGUI.DefaultBoardSize;
            end
            obj.boardSize = boardSize;
            
            obj.fig = openfig('OthelloGUI.fig');
            obj.fig.CloseRequestFcn = onClose;
            
            posCenter = round(get(groot,'ScreenSize') - obj.fig.Position)/2;
            obj.fig.Position(1:2) = posCenter(3:4);
            
            c = obj.fig.Children;
            obj.ax = obj.board(c(end), boardSize);
            
            obj.stateBar = c(1);
            
            obj.labelScores = gobjects(2,1);
            obj.labelScores(Player.White) = c(2);
            obj.labelScores(Player.Black) = c(3);
            
            obj.label = gobjects(2,1);
            obj.label(Player.White) = c(4);
            obj.label(Player.Black) = c(5);
            
            DPI = get(groot,'ScreenPixelsPerInch')/72;
            tokenSize = 0.87*obj.ax.Position(3)/max(boardSize);
            tokenBorderWidth = .03*tokenSize;
            line(obj.ax,zeros(2),zeros(2),...
                'MarkerEdgeColor',0.5*ones(1,3),...
                'MarkerSize',tokenSize/DPI,...
                'LineWidth',tokenBorderWidth/DPI,...
                'LineStyle','none');
            obj.tokens = obj.ax.Children;
            obj.tokens(Player.White).XData = [];
            obj.tokens(Player.White).YData = [];
            obj.tokens(Player.White).MarkerFaceColor = 'w';
            obj.tokens(Player.White).Marker = 'o';
            obj.tokens(Player.Black).XData = [];
            obj.tokens(Player.Black).YData = [];
            obj.tokens(Player.Black).MarkerFaceColor = 'k';
            obj.tokens(Player.Black).Marker = 'o';
            
            obj.ax.ButtonDownFcn = @obj.axes_ButtonDownFcn;
        end
        
        function delete(obj)
            closereq;
        end
        
        function dispMessage(obj, str)
            obj.stateBar.String = str;
        end
        
        function setMessageColor(obj, fgColor, bgColor)
            obj.stateBar.ForegroundColor = fgColor;
            obj.stateBar.BackgroundColor = bgColor;
        end
        
        function dispScore(obj, player, score)
            obj.labelScores(player).String = num2str(score);
        end
        
        function setLabel(obj, player, str)
            obj.label(player).String = str;
        end
        
        function plotTokens(obj, rows, cols, player)
            obj.tokens(player).XData = cols;
            obj.tokens(player).YData = rows;
            drawnow
        end
    end
    methods (Access = private)
        function axes_ButtonDownFcn(obj, src, ~)
            coords = get(src,'CurrentPoint');
            coords = ceil(coords(1,[2 1])-.5);
            if all(coords >= 1 & coords <= obj.boardSize)
                obj.clickedCell = coords;
                notify(obj, 'Click');
            end
        end
        
        function ax = board(obj, ax, dim)
        %BOARD Displays a board
        %   BOARD(ax,DIM) specifies the board dimensions.
            if all(size(dim) == [1 1])
                dim = [dim dim];
            end
            ax.XAxis.TickValues = (0:dim(2)) + 0.5;
            ax.XLim = [0 dim(2)] + 0.5;
            ax.YAxis.TickValues = (0:dim(1)) + 0.5;
            ax.YLim = [0 dim(1)] + 0.5;

            ax.PlotBoxAspectRatio = [1 1 1];
        end
    end
end
