(*
OmniFocus Markdown Report Generator v 0.9

Generate a nice markdown report of what you've done over a period of time in OmniFocus. Can be set to ignore folders, and tweak the scope of reporting. 

Maybe future versions will make it easier to tweak formatting and data scraping from the OF database
*)

on run
	tell application "OmniFocus"
		set endDate to current date
		set hours of endDate to 0
		set minutes of endDate to 0
		set seconds of endDate to 0
		set dteNow to endDate + (23 * hours) + (59 * minutes) + 59
		
		-- set theDateRange to last week
		set endDate to endDate - 7 * days
		set dteNow to dteNow - 7 * days
		repeat until (weekday of endDate) = Sunday
			set endDate to endDate - 1 * days
		end repeat
		repeat until (weekday of dteNow) = Saturday
			set dteNow to dteNow + 1 * days
		end repeat
		set ExportList to ""
		-- set ExportList to "Current List of Active Projects" & return & "---" & return & dteNow & return & return as Unicode text
		
		(*Scoping Variables: 
        ignoreList includes a list of folders that contain projects you'd like to ignore. 
        timeScope is the period of time you'd like to review over in days
        reportName is the filename of the resulting report. It's plaintext, so you can export it to any wrapper you'd like, such as txt, rtf, etc.
        *)
		set ignoreList to {""}
		set timeScope to 7
		set reportName to "Report of last " & timeScope & " days" & ".md"
		
		tell default document
			-- Get list of folders toss user specified projects and run list through project subroutine to build string for export
			-- repeat with oFolder in (flattened folders where hidden is false) as list
			--     if ignoreList does not contain name of oFolder then
			--         set ExportList to ExportList & my IndentAndProjects(oFolder, dteNow) & return
			--     end if
			-- end repeat
			
			-- Concatenate additional information onto this string
			set ExportList to ExportList & return & return & "Completed Tasks" & return & "---" & return & endDate & " ~ " & dteNow & return
			
			-- Grab list of all tasks completed during scope of report. It would be faster to ignore tasks from the ignoreList at this stage, but I couldn't figure out a way to get that to work here.
			
			set refDoneInLastWeek to a reference to (flattened tasks where (completion date ≥ endDate))
			
			-- Build lists of information from each of those tasks. You can scrape additional properties here if you'd like, such as notes attached to tasks, due dates, flag status etc.
			-- To do so, add the property variable to the set clause, and add the property your scraping in the to clause list at the same list position. Be warned, the more properties, the more
			-- iterations through a database that can get quite large depending on scope. This probably affects runtime the most.
			set {lstName, lstContext, lstProject, lstDate, lstFolder} to {name, name of its context, name of its containing project, completion date, name of folder of its containing project} of refDoneInLastWeek
			
			-- Make strings of all the values we scraped for tasks that don't live in folders from our ignore list, apply some formatting and add them to our buffer
			set strText to ""
			repeat with iTask from 1 to length of lstName
				if ignoreList does not contain (item iTask of lstFolder) then
					set {strName, varContext, varProject, varDate} to {item iTask of lstName, item iTask of lstContext, item iTask of lstProject, item iTask of lstDate}
					if varDate is not missing value then set strText to strText & short date string of varDate & " - "
					if varProject is not missing value then set strText to strText & " [" & varProject & "] - "
					set strText to strText & strName
					if varContext is not missing value then set strText to strText & " @" & varContext
					set strText to strText & "  " & return
				end if
			end repeat
			
		end tell
		
		-- Write the string out to a buffer
		
		set ExportList to ExportList & strText as Unicode text
		
		-- Name the report, write to file.
		set fn to choose file name with prompt "Name this file" default name reportName default location (path to desktop folder)
		tell application "System Events"
			set fid to open for access fn with write permission
			write ExportList to fid as «class utf8»
			close access fid
		end tell
	end tell
end run

-- Formatting and string building for active projects. Takes flattened list of folders and are active as of todays date
-- on IndentAndProjects(oFolder, dteNow)
--     tell application id "OFOC"
--         set strIndent to "##"
--         set oParent to container of oFolder
--         repeat while class of oParent is folder
--             set strIndent to strIndent & "#"
--             set oParent to container of oParent
--         end repeat
--         
--         set {dlm, my text item delimiters} to {my text item delimiters, return & return}
--         set strActive to (name of (projects of oFolder where it is not singleton action holder and its status is active and its defer -- date is missing value or defer date < dteNow)) as string
--         set my text item delimiters to dlm
--         
--         return strIndent & name of oFolder & return & strActive & return
--     end tell
-- end IndentAndProjects