function eta = iGetTimeString( remainingtime )
%

if isnan(remainingtime)
    eta = 'N/A';
    return
end
if remainingtime > 172800 % 2 days
    eta = sprintf( '%d days', round(remainingtime/86400) );
else
    if remainingtime > 7200 % 2 hours
        eta = sprintf( '%d hours', round(remainingtime/3600) );
    else
        if remainingtime > 120 % 2 mins
            eta = sprintf( '%d mins', round(remainingtime/60) );
        else
            % Seconds
            remainingtime = round( remainingtime );
            if remainingtime > 1
                eta = sprintf( '%d secs', remainingtime );
            elseif remainingtime == 1
                eta = '1 sec';
            else
                eta = 'Soon completed.'; % Nearly done (<1sec)
            end
        end
    end
end