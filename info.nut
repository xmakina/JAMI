class JAMI extends AIInfo {
  function GetAuthor()      { return "Xander"; }
  function GetName()        { return "JAMI"; }
  function GetDescription() { return "Just Another Moronic Intelligence"; }
  function GetVersion()     { return 3; }
  function GetDate()        { return "2009-08-13"; }
  function CreateInstance() { return "JAMI"; }
  function GetShortName()   { return "JAMI"; }
}
/* Tell the core we are an AI */
RegisterAI(JAMI());
