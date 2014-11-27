function [ ] = printTitle( title, short, L )
% printTitle( title , short=0, length = 60)
% disp a formated title. 
%'title' is surounded by '-' to fill up a string of length 'length'
% if short flag is on, replace a few '-' by spaces

% Author: Julien diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


if(nargin<2) short = 0;  end;
if(nargin<3) L     = 60; end;

T(1:L) = '-';
T = [T '\n'];
if(short)
    T(1:3)         = ' ';
    T(end-5:end-2) = ' ';
end;

if(nargin==0 || isempty(title)) fprintf(T); return; end;


s = round(L/2 - length(title)/2) + mod(L,2);
e = round(L/2 + length(title)/2) +1;
T(s:e) = [' ' title ' '];
fprintf(T);
