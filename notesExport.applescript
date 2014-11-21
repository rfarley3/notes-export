-- Exports OS X Notes.app content
-- Can specify which Account and which Folder
-- Output is a html file per note, named with cdate

on buildTitle(originalText)
	set normalizedText to my replace(originalText, ":", "-")
	set finalTitle to my firstChars(normalizedText, 100)
	return finalTitle
end buildTitle


on replace(originalText, fromText, toText)
	set AppleScript's text item delimiters to the fromText
	set the item_list to every text item of originalText
	set AppleScript's text item delimiters to the toText
	set originalText to the item_list as string
	set AppleScript's text item delimiters to ""
	return originalText
end replace


on getNameOfTargetAccount(thisPrompt)
	tell application "Notes"
		if the (count of accounts) is greater than 1 then
			set theseAccountNames to the name of every account
			set thisAccountName to (choose from list theseAccountNames with prompt thisPrompt)
			if thisAccountName is false then error number -128
			set thisAccountName to thisAccountName as string
		else
			set thisAccountName to the name of account 1
		end if
		return thisAccountName
	end tell
end getNameOfTargetAccount


on getNameOfTargetFolder(thisPrompt)
	tell application "Notes"
		if the (count of folders) is greater than 1 then
			set theseFolderNames to the name of every folder
			-- filter out to ones from specific account
			set thisFolderName to (choose from list theseFolderNames with prompt thisPrompt)
			if thisFolderName is false then error number -128
			set thisFolderName to thisFolderName as string
		else
			set thisFolderName to the name of folder 1
		end if
		return thisFolderName
	end tell
end getNameOfTargetFolder


on getAllNotesFromAccountNamed(targetAccountName)
	tell application "Notes"
		set the matchingNotes to {}
		repeat with i from 1 to the count of notes
			set thisNote to note i
			set thisItem to thisNote
			-- walk up the container chain until the account container is reached
			repeat
				set thisContainer to the container of thisItem
				if (the class of thisContainer) is account then
					if the name of thisContainer is targetAccountName then
						set the end of matchingNotes to thisNote
					end if
					exit repeat
				else
					set thisItem to thisContainer
				end if
			end repeat
		end repeat
		return matchingNotes
	end tell
end getAllNotesFromAccountNamed


on getAllNotesFromFolderNamed(targetAccountNotes, targetFolderName)
	tell application "Notes"
		set the matchingNotes to {}
		repeat with i from 1 to the count of targetAccountNotes
			set thisNote to (item i of targetAccountNotes)
			set thisItem to thisNote
			-- walk up the container chain until the folder container is reached
			repeat
				set thisContainer to the container of thisItem
				if (the class of thisContainer) is folder then
					if the name of thisContainer is targetFolderName then
						-- doesn't check if nested folders under same account...
						set the end of matchingNotes to thisNote
					end if
				else
					-- we've reached an account, folder not found
					exit repeat
				end if
				set thisItem to thisContainer
			end repeat
		end repeat
		return matchingNotes
	end tell
end getAllNotesFromFolderNamed


on firstChars(originalText, maxChars)
	if length of originalText is less than maxChars then
		return originalText
	else
		set limitedText to text 1 thru maxChars of originalText
		return limitedText
	end if
end firstChars


on writeToFile(filename, filecontents)
	set the output to open for access file filename with write permission
	set eof of the output to 0
	write ((ASCII character 239) & (ASCII character 187) & (ASCII character 191)) to output
	write filecontents to the output starting at eof as Çclass utf8È
	close access the output
end writeToFile


-- & "***No error checking, little feedback, use at your own risk. If you have same-named folders under folders under the account you select (is that even possible?), then you may export the contents of both. If they have same-named notes with the same creation dates, then they will overwrite eachother.***
--
--"
tell application "Notes"
	activate
	display dialog "This is an export utility for Notes.app.

" & "If you have multiple accounts, then you will be prompted to select which account.

If you have multiple folders, then you will be prompted select which folder.

You will be prompted to select a destination folder. If it doesn't exist, then make it and then come back.

Each note will be exported as a simple HTML file named:
<Account>:<Folder>:<Creation Date>:<Title>.html" with title "Notes Export" buttons {"Cancel", "Proceed"} cancel button "Cancel" default button "Proceed"
	
	set thisAccountName to (my getNameOfTargetAccount("Choose an account:"))
	set thisFolderName to (my getNameOfTargetFolder("Choose a folder:"))
	set allNotesOfAccount to (my getAllNotesFromAccountNamed(thisAccountName))
	set allNotesOfFolder to (my getAllNotesFromFolderNamed(allNotesOfAccount, thisFolderName))
	set exportFolder to choose folder
	
	--display dialog "Exporting " & (count of allNotesOfFolder) & " notes from \"" & thisFolderName & "\" to " & exportFolder with title "Confirm" buttons {"Cancel", "Proceed"} cancel button "Cancel" default button "Proceed"
	
	repeat with i from 1 to the count of allNotesOfFolder
		set noteName to name of (item i of allNotesOfFolder)
		set noteID to id of (item i of allNotesOfFolder)
		set noteDateRaw to the creation date of (item i of allNotesOfFolder)
		set noteDate to (my date_format(noteDateRaw))
		set noteAccount to thisAccountName
		set noteFolder to thisFolderName
		set noteTitle to my buildTitle(noteAccount & ":" & noteFolder & ":" & noteDate & ":" & noteName)
		set noteBody to body of (item i of allNotesOfFolder)
		set filename to ((exportFolder as string) & noteTitle & ".html")
		my writeToFile(filename, noteBody as text)
	end repeat
	
	display alert "Notes Export" message "All " & ((count of allNotesOfFolder) as string) & " notes were exported successfully." as informational
end tell


-- found on the interwebs
-- by Kai Edwards
-- http://macscripter.net/viewtopic.php?id=24737
-- http://bbs.applescript.net/viewtopic.php?pid=56878#p56878
on date_format(old_date)
	-- get the date as an AppleScript date
	--date old_date
	--> This: date "12 April 2006" [ coerce date string to date ]
	--> Compiles to: date "Wednesday, April 12, 2006 00:00:00"
	
	-- get the date elements [year, month & day] from the date
	
	set {year:y, month:m, day:d} to result
	--> y = 2006, m = April, d = 12
	
	-- We want to shift these numbers so we can add them to get our final form
	
	y * 10000
	--> 2006 * 10000
	--> 20060000
	
	result + m * 100
	--> [m * 100] = [April * 100] = [4 * 100] = 400 [ coerced to number ]
	--> 20060000 + 400 
	--> 20060400 the year followed by the month with leading zero, the day 00.
	
	result + d
	--> 20060400 + 12
	--> 20060412 the year, the month with leading zero, the day of the month.
	
	-- now coerce the result to string
	
	result as string
	--> 20060412 as string
	--> "20060412"
	
	-- tell the result to format the output 
	-- tell avoids having to save the result as a variable and repeat it several times
	
	tell result -- tell "20060412"
		
		text 1 thru 4
		--> text 1 thru 4 of "20060412" = "2006"
		
		--result & "."
		--> "2006" & "."
		--> "2006."
		
		result & text 5 thru 6
		--> text 5 thru 6 of "20060412" = "04"
		--> "2006." & "04"
		--> "2006.04"
		
		--result & "."
		--> "2006.04" & "."
		--> "2006.04."
		
		result & text 7 thru 8
		--> text 7 thru 8 of "20060412" = "12"
		--> "2006.04." & "12"
		--> "2006.04.12" [ final result returned by handler ]
		
	end tell
end date_format
