unit app_view;

interface

uses
  System.DateUtils,
  System.Generics.Collections,
  System.StrUtils,
  System.SysUtils,
  System.Variants,
  SynCommons,
  SynCrypto,
  SynLog,
  mORMot,
  mORMotMVC,
  app_model,
  app_globals;

type
  IFrontEnd = interface(IMVCApplication)
    ['{C5072829-B908-4F3A-BECA-E5F902FE8511}']  // ctrl+shift+G
    procedure Login(var Scope: Variant);
    procedure Useful(var Scope: Variant);
    procedure Pictures(var Scope: Variant);
    procedure About(var Scope: Variant);
    function doAddWord(const WordSelf: RawUTF8; const WordEnglish: RawUTF8): TMVCAction;
    function doLogin(const PlainPassword: RawUTF8): TMVCAction;
    function doLogout: TMVCAction;
    function doRemoveWord(const Id: Integer): TMVCAction;
    function goToUseful: TMVCAction;
    function goToPictures: TMVCAction;
    function goToAbout: TMVCAction;
    function doAddLink(const LinkSelf: RawUTF8; const LinkDesp: RawUTF8): TMVCAction;
    function doRemoveLink(const Id: Integer): TMVCAction;
    function doAddPicture(const Picture: RawUTF8): TMVCAction;
    function doRemovePicture(const Id: Integer): TMVCAction;
  end;

  TFrontEnd = class(TMVCApplication, IFrontEnd)
  protected
    procedure ExpirationToText(const Value: Variant; out Result: Variant);
  public
    procedure Start(aServer: TSQLRestServer); reintroduce;
    procedure Default(var Scope: Variant);
    procedure Login(var Scope: Variant);
    procedure Useful(var Scope: Variant);
    procedure About(var Scope: Variant);
    procedure Pictures(var Scope: Variant);
    function doLogin(const PlainPassword: RawUTF8): TMVCAction;
    function doLogout: TMVCAction;
    function goToUseful: TMVCAction;
    function goToPictures: TMVCAction;
    function goToAbout: TMVCAction;

    function doAddWord(const WordSelf: RawUTF8; const WordEnglish: RawUTF8): TMVCAction;
    function doRemoveWord(const Id: Integer): TMVCAction;

    function doAddLink(const LinkSelf: RawUTF8; const LinkDesp: RawUTF8): TMVCAction;
    function doRemoveLink(const Id: Integer): TMVCAction;

    function doAddPicture(const Picture: RawUTF8): TMVCAction;
    function doRemovePicture(const Id: Integer): TMVCAction;
  end;

implementation

{ TFrontEnd }

procedure TFrontEnd.About(var Scope: Variant);
begin
  // About.html page
end;

procedure TFrontEnd.Default(var Scope: Variant);
var
  Words: Variant;
  Filtered: TDocVariantData;
  ndx: Integer;
  WordId: Integer;
  WordSelf, WordEnglish: RawUTF8;

begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin // already logged in?
    Words := RestModel.RetrieveDocVariantArray(TWord, '', '', [], 'ID,Word,English'); // get all licenses from the database
    Filtered.Init();
    with _Safe(Words)^ do begin
      for ndx := 0 to Count - 1 do begin
        WordId := Values[ndx].ID;
        WordSelf := VariantToUTF8(Values[ndx].Word);
        WordEnglish := VariantToUTF8(Values[ndx].English);
        Filtered.AddItem(_JsonFastFmt('{"id":?,"word":?, "english":?}', [], [WordId, WordSelf, WordEnglish]));
      end;
    end;
    SQLite3Log.Add.Log(sllDebug, 'TFrontEnd.Default - Filtered: %', [Filtered.ToJSON]);
    _ObjAddProps(['words', Variant(Filtered)], Scope); // add to passed-in data
  end
  else begin // redirect to the login page
    raise EMVCApplication.CreateGotoView('Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED);
  end;
end;

function TFrontEnd.doAddLink(const LinkSelf, LinkDesp: RawUTF8): TMVCAction;
var
  aLink: TLink;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin
    if Length(LinkSelf) >= 1 then begin
      aLink := TLink.Create;
      try
        aLink.Link := LinkSelf;
        aLink.Desp := LinkDesp;
        RestModel.Add(aLink, True);
        GotoView(Result, 'Useful', [], HTTP_SEEOTHER);
      finally
        aLink.Free;
      end;
    end
    else begin
      GotoView(Result, 'Useful', ['Scope', _ObjFast(['ar_msg', 'Invalid Link'])], HTTP_BADREQUEST);
    end;
  end
  else begin
    GotoView(Result, 'Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED); // redirect to login
  end;
end;


function TFrontEnd.doAddPicture(const Picture: RawUTF8): TMVCAction;
var
  aPic: TPicture;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin
    if Length(Picture) >= 1 then begin
      aPic := TPicture.Create;
      try
        aPic.Picture := Picture;
        RestModel.Add(aPic, True);
        GotoView(Result, 'Pictures', [], HTTP_SEEOTHER);
      finally
        aPic.Free;
      end;
    end
    else begin
      GotoView(Result, 'Pictures', ['Scope', _ObjFast(['ar_msg', 'Invalid Picture'])], HTTP_BADREQUEST);
    end;
  end
  else begin
    GotoView(Result, 'Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED); // redirect to login
  end;
end;

function TFrontEnd.doAddWord(const WordSelf: RawUTF8; const WordEnglish: RawUTF8): TMVCAction;
var
  aWord: TWord;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin
    if Length(WordSelf) >= 1 then begin
      aWord := TWord.Create;
      try
        aWord.Word := WordSelf;
        aWord.English := WordEnglish;
        RestModel.Add(aWord, True);
        GotoView(Result, 'Default', [], HTTP_SEEOTHER);
      finally
        aWord.Free;
      end;
    end
    else begin
      GotoView(Result, 'Default', ['Scope', _ObjFast(['ar_msg', 'Invalid Word'])], HTTP_BADREQUEST);
    end;
  end
  else begin
    GotoView(Result, 'Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED); // redirect to login
  end;
end;


function TFrontEnd.doLogin(const PlainPassword: RawUTF8): TMVCAction;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then
    GotoView(Result, 'Default', [], HTTP_SEEOTHER) // already logged in
  else begin
    if PlainPassword = 'admin' then begin
      CurrentSession.Initialize(); // start the session
      GotoView(Result, 'Default', [], HTTP_SEEOTHER); // redirect to the main page
    end
    else begin
      GotoView(Result, 'Login', ['Scope', _ObjFast(['err', 'Authentication failed'])], HTTP_UNAUTHORIZED); // log in failed
    end;
  end;
end;


function TFrontEnd.doLogout: TMVCAction;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then
    CurrentSession.Finalize;
  GotoView(Result, 'Login', [], HTTP_SEEOTHER);
end;


function TFrontEnd.doRemoveLink(const Id: Integer): TMVCAction;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin
    if (Id <> 0) and RestModel.Delete(TLink, Id) then // remove license from database
      GotoView(Result, 'Useful', [], HTTP_SEEOTHER)
    else
      GotoView(Result, 'Useful', [], HTTP_BADREQUEST);
  end
  else begin
    GotoView(Result, 'Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED); // redirect to login
  end;
end;


function TFrontEnd.doRemovePicture(const Id: Integer): TMVCAction;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin
    if (Id <> 0) and RestModel.Delete(TPicture, Id) then // remove license from database
      GotoView(Result, 'Pictures', [], HTTP_SEEOTHER)
    else
      GotoView(Result, 'Pictures', [], HTTP_BADREQUEST);
  end
  else begin
    GotoView(Result, 'Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED); // redirect to login
  end;
end;

function TFrontEnd.doRemoveWord(const Id: Integer): TMVCAction;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin
    if (Id <> 0) and RestModel.Delete(TWord, Id) then // remove license from database
      GotoView(Result, 'Default', [], HTTP_SEEOTHER)
    else
      GotoView(Result, 'Default', [], HTTP_BADREQUEST);
  end
  else begin
    GotoView(Result, 'Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED); // redirect to login
  end;
end;


procedure TFrontEnd.ExpirationToText(const Value: Variant; out Result: Variant);
begin
  Result := 'In a day';
end;

function TFrontEnd.goToAbout: TMVCAction;
begin
  GotoView(Result, 'About', [], HTTP_SEEOTHER);
end;

function TFrontEnd.goToPictures: TMVCAction;
begin
  GotoView(Result, 'Pictures', [], HTTP_SEEOTHER);
end;

function TFrontEnd.goToUseful: TMVCAction;
begin
  GotoView(Result, 'Useful', [], HTTP_SEEOTHER);
end;


procedure TFrontEnd.Login(var Scope: Variant);
begin
//  if CurrentSession.CheckAndRetrieve <> 0 then
//    raise EMVCApplication.CreateGotoView('Default', [], HTTP_SEEOTHER);
end;


procedure TFrontEnd.Pictures(var Scope: Variant);
var
  Pictures: Variant;
  Filtered: TDocVariantData;
  ndx: Integer;
  PicId: Integer;
  ImageLink: RawUTF8;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin // already logged in?
    Pictures := RestModel.RetrieveDocVariantArray(TPicture, '', '', [], 'ID,Picture'); // get all licenses from the database
    Filtered.Init();
    with _Safe(Pictures)^ do begin
      for ndx := 0 to Count - 1 do begin
        PicId := Values[ndx].ID;
        ImageLink := VariantToUTF8(Values[ndx].Picture);
        Filtered.AddItem(_JsonFastFmt('{"id":?,"picture":?}', [], [PicId, ImageLink]));
      end;
    end;
    SQLite3Log.Add.Log(sllDebug, 'TFrontEnd.Default - Filtered: %', [Filtered.ToJSON]);
    _ObjAddProps(['Pictures', Variant(Filtered)], Scope); // add to passed-in data
  end
  else begin // redirect to the login page
    raise EMVCApplication.CreateGotoView('Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED);
  end;
end;


procedure TFrontEnd.Start(aServer: TSQLRestServer);
begin
  inherited Start(aServer, TypeInfo(IFrontEnd));
  fMainRunner := TMVCRunOnRestServer.Create(Self, nil, '', nil,
    [publishStatic, registerORMTableAsExpressions, bypassAuthentication]); // reuse the REST server for the views
end;


procedure TFrontEnd.Useful(var Scope: Variant);
var
  Links: Variant;
  Filtered: TDocVariantData;
  ndx: Integer;
  LinkId: Integer;
  LinkSelf, LinkDesp: RawUTF8;
begin
  if CurrentSession.CheckAndRetrieve <> 0 then begin // already logged in?
    Links := RestModel.RetrieveDocVariantArray(TLink, '', '', [], 'ID,Link,Desp'); // get all licenses from the database
    Filtered.Init();
    with _Safe(Links)^ do begin
      for ndx := 0 to Count - 1 do begin
        LinkId := Values[ndx].ID;
        LinkSelf := VariantToUTF8(Values[ndx].Link);
        LinkDesp := VariantToUTF8(Values[ndx].Desp);
        Filtered.AddItem(_JsonFastFmt('{"id":?,"link":?, "desp":?}', [], [LinkId, LinkSelf, LinkDesp]));
      end;
    end;
    SQLite3Log.Add.Log(sllDebug, 'TFrontEnd.Default - Filtered: %', [Filtered.ToJSON]);
    _ObjAddProps(['Links', Variant(Filtered)], Scope); // add to passed-in data
  end
  else begin // redirect to the login page
    raise EMVCApplication.CreateGotoView('Login', ['Scope', _ObjFast(['err', 'Authentication required'])], HTTP_UNAUTHORIZED);
  end;
end;

end.
