/*
Kakutou 2004!!!
	version 1.0
	Code and animations done by PsychoKick, circa 2002.
	Sounds ripped from Sega's Virtua Fighter PC and edited by PsychoKick.
	Very special thanks to the UT community for sharing the knowledge to make this mod possible.
	Dedicated to all who practice the martial arts, whether in reality or in games.
	UT2004 Code Modifications for Instant Action: Rythmix - Rythmix@gmail.com - www.rythm-nation.net
*/

class K2k4MutConfig extends GUIPage;

var moEditBox MinBlockBox, MaxBlockBox, HitBonusBox, GuardBonusBox, MissPenaltyBox, LeapBonusBox;

// Called when our GUI component is initiated (in this case our config window)
function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner); // Call Parent's InitComponent

    // Assign variables to EditBoxes that were created in the default properties
    MinBlockBox = moEditBox(Controls[4]);
    MaxBlockBox = moEditBox(Controls[5]);
    HitBonusBox = moEditBox(Controls[6]);
	GuardBonusBox = moEditBox(Controls[7]);
	MissPenaltyBox = moEditBox(Controls[8]);
	LeapBonusBox = moEditBox(Controls[10]);

    // Set the EditBoxes to be integer only because we are only dealing with numbers
    MinBlockBox.IntOnly(true);
    MaxBlockBox.IntOnly(true);
    HitBonusBox.IntOnly(true);
	GuardBonusBox.IntOnly(true);
	MissPenaltyBox.IntOnly(true);
	LeapBonusBox.IntOnly(true);

    // Set the EditBoxes' text to our mutator's config variables' values
    MinBlockBox.SetText(string(class'MutKakutou2k4'.default.MinBlock));
    MaxBlockBox.SetText(string(class'MutKakutou2k4'.default.MaxBlock));
    HitBonusBox.SetText(string(class'MutKakutou2k4'.default.HitBonus));
	GuardBonusBox.SetText(string(class'MutKakutou2k4'.default.GuardBonus));
	MissPenaltyBox.SetText(string(class'MutKakutou2k4'.default.MissPenalty));
	LeapBonusBox.SetText(string(class'MutKakutou2k4'.default.LeapBonus));
}

// Called when the OK button is clicked
function bool internalOnClick(GUIComponent Sender)
{
//Sanity checking for values
	if ( int(MinBlockBox.GetText()) < 0 )
		MinBlockBox.SetText(string('0'));
	if ( int(MaxBlockBox.GetText()) < 0 )
		MaxBlockBox.SetText(string('0'));

	if ( int(MinBlockBox.GetText()) > 360 )
		MinBlockBox.SetText(string('360'));
	if ( int(MaxBlockBox.GetText()) > 360 )
		MaxBlockBox.SetText(string('360'));

	if ( int(MinBlockBox.GetText()) > int(MaxBlockBox.GetText()) )
		MinBlockBox.SetText( MaxBlockBox.GetText() );

	if ( int(HitBonusBox.GetText()) < 0 )
		HitBonusBox.SetText(string('0'));
	if ( int(GuardBonusBox.GetText()) < 0 )
		GuardBonusBox.SetText(string('0'));
	if ( int(MissPenaltyBox.GetText()) < 0 )
		MissPenaltyBox.SetText(string('0'));
	if ( int(LeapBonusBox.GetText()) < 0 )
		LeapBonusBox.SetText(string('0'));

    // Set our Mutator's variables to the new variables that were set by the user
    class'MutKakutou2k4'.default.MinBlock = int(MinBlockBox.GetText());
    class'MutKakutou2k4'.default.MaxBlock = int(MaxBlockBox.GetText());
    class'MutKakutou2k4'.default.HitBonus = int(HitBonusBox.GetText());
    class'MutKakutou2k4'.default.GuardBonus = int(GuardBonusBox.GetText());
	class'MutKakutou2k4'.default.MissPenalty = int(MissPenaltyBox.GetText());
	class'MutKakutou2k4'.default.LeapBonus = int(LeapBonusBox.GetText());
    class'MutKakutou2k4'.static.StaticSaveConfig();  // Save all the Mutator's config variables

    class'MutKakutouArena'.default.MinBlock = int(MinBlockBox.GetText());
    class'MutKakutouArena'.default.MaxBlock = int(MaxBlockBox.GetText());
    class'MutKakutouArena'.default.HitBonus = int(HitBonusBox.GetText());
    class'MutKakutouArena'.default.GuardBonus = int(GuardBonusBox.GetText());
	class'MutKakutouArena'.default.MissPenalty = int(MissPenaltyBox.GetText());
	class'MutKakutouArena'.default.LeapBonus = int(LeapBonusBox.GetText());
    class'MutKakutouArena'.static.StaticSaveConfig();  // Save all the Mutator's config variables

    Controller.CloseMenu(false);    // Close the window

    return true;    // Return True (hard to figure out eh?) ;)
}

function bool ResetToDefaults(GUIComponent Sender)
{
	MinBlockBox.SetText(string('90'));
	MaxBlockBox.SetText(string('135'));

	HitBonusBox.SetText(string('10'));
	GuardBonusBox.SetText(string('3'));
	MissPenaltyBox.SetText(string('3'));
	LeapBonusBox.SetText(string('100'));

    return true;    // Return True (hard to figure out eh?) ;)
}

defaultproperties
{
    Begin Object Class=GUIButton name=DialogBackground  // The window's background
        WinWidth=1.0            // Set Window's width
        WinHeight=1.0           // Set Window's height
        WinTop=0            // Set the windows location on the Y axis
        WinLeft=0           // Set the windows location on the X axis
        bAcceptsInput=false     // Since its just a background it wont accept input
        bNeverFocus=true        // Just a background, no need for focus
        StyleName="ComboListBox"    // The style of the background
        bBoundToParent=true     // is it bound to its parent window?
        bScaleToParent=true     // is it in scale to its parent window?
    End Object
    Controls(0)=GUIButton'DialogBackground' // Sets Controls[0] to the DialogBackround

    Begin Object Class=GUIButton Name=OkButton  // An "OK" Button
        Caption="OK"                // The button's caption
        WinWidth=0.2
        WinHeight=0.04
        WinLeft=0.6
        WinTop=0.9
        OnClick=InternalOnClick         // Assigns the button's OnClick to our InternalOnClick function
		bBoundToParent=true
    End Object
    Controls(1)=GUIButton'OkButton'         // Sets Controls[1] to the OkButton

    Begin Object class=GUILabel Name=DialogText // A text label
        Caption="Kakutou2K4"
        TextALign=TXTA_Center           // Text allignment
        TextColor=(R=220,G=180,B=0,A=255)   // Text color
        TextFont="UT2HeaderFont"        // Text font
        WinWidth=1.000000
        WinHeight=20.000000
        WinLeft=0.000000
        WinTop=0.1
		bBoundToParent=true
    End Object
    Controls(2)=GUILabel'DialogText'

    Begin Object class=GUILabel Name=DialogText2    // Another text label
        Caption="Mutator Configuration"
        TextALign=TXTA_Center
        TextColor=(R=220,G=180,B=0,A=255)
        TextFont="UT2MenuFont"
        WinWidth=1.000000
        WinHeight=20.000000
        WinLeft=0.000000
        WinTop=0.2
		bBoundToParent=true
    End Object
    Controls(3)=GUILabel'DialogText2'

    Begin Object class=moEditBox Name=MinBlock // An edit box (for our MinBlock)
//        WinWidth=0.431641
		WinWidth=0.4
        WinHeight=0.04
//        WinLeft=0.293750
		WinLeft=0.05
        WinTop=0.3
        Caption="Min Block (0-360)"
        bReadOnly=false             // Will take Input, therefor isn't readonly
		bBoundToParent=true
    End Object
    Controls(4)=moEditBox'MinBlock'        // Set Controls[4] to the MinBlock

    Begin Object class=moEditBox name=MaxBlock // Another edit box (for our MaxBlock)
//        WinWidth=0.431641
		WinWidth=0.4
        WinHeight=0.04
//        WinLeft=0.293750
		WinLeft=0.55
        WinTop=0.3
        Caption="Max Block (0-360)"
        bReadOnly=false
		bBoundToParent=true
    End Object
    Controls(5)=moEditBox'MaxBlock'        // Set Controls[5] to the MaxBlock

    Begin Object class=moEditBox name=HitBonus
//        WinWidth=0.431641
		WinWidth=0.4
        WinHeight=0.04
//        WinLeft=0.293750
		WinLeft=0.05
        WinTop=0.5
        Caption="Hit Bonus"
        bReadOnly=false
		bBoundToParent=true
    End Object
    Controls(6)=moEditBox'HitBonus'

    Begin Object class=moEditBox name=GuardBonus
//        WinWidth=0.431641
		WinWidth=0.4
        WinHeight=0.04
//        WinLeft=0.293750
		WinLeft=0.55
        WinTop=0.5
        Caption="Block Bonus"
        bReadOnly=false
		bBoundToParent=true
    End Object
    Controls(7)=moEditBox'GuardBonus'

    Begin Object class=moEditBox name=MissPenalty
//        WinWidth=0.431641
		WinWidth=0.4
        WinHeight=0.04
//        WinLeft=0.293750
		WinLeft=0.05
        WinTop=0.6
        Caption="Miss Penalty"
        bReadOnly=false
		bBoundToParent=true
    End Object
    Controls(8)=moEditBox'MissPenalty'

    Begin Object class=GUIButton name=ResetButton  // A "Reset" Button
        Caption="Reset to Defaults"                // The button's caption
        WinWidth=0.2
        WinHeight=0.04
        WinLeft=0.2
        WinTop=0.9
        OnClick=ResetToDefaults         // Assigns the button's OnClick to our InternalOnClick function
		bBoundToParent=true
    End Object
    Controls(9)=GUIButton'ResetButton'         // Sets Controls[6] to the OkButton

    Begin Object class=moEditBox name=LeapBonus
//        WinWidth=0.431641
		WinWidth=0.4
        WinHeight=0.04
//        WinLeft=0.293750
		WinLeft=0.55
        WinTop=0.6
        Caption="Leap % Bonus"
        bReadOnly=false
		bBoundToParent=true
    End Object
    Controls(10)=moEditBox'LeapBonus'

    // The Window's own properties (MJMutConfig)
    WinLeft=0
    WinTop=0.2
    WinWidth=1
    WinHeight=0.6
    bRequire640x480=True        // Required Minimum resolution
}
