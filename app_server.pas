unit app_server;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Variants,
  SynCommons,
  SynCrypto,
  SynLog,
  mORMot,
  mORMotSQLite3,
  SynSQLite3Static,
  app_model,
  app_interface,
  app_globals;

type
  TAppServer = class(TInterfacedObject, IAppServer)
  private
  public
    function GetAllWords: Variant;
    function GetAllLinks: Variant;
    function GetAllPictures: Variant;
  end;

implementation



{ TWordServer }

function TAppServer.GetAllLinks: Variant;
var
  aLinkList: TObjectList<TLink>;
  aLink: TLink;
  Doc: TDocVariantData;
begin
  TDocVariant.NewFast(Result);
  aLinkList := aRestServer.RetrieveList<TLink>();
  Doc.Init;
  try
    for aLink in aLinkList do begin
      Doc.AddItem(_JsonFastFmt('{"link":?,"desp":?}',[],[aLink.Link, aLink.Desp]));
    end;
    _ObjAddProps(['links', Variant(Doc)], Result);
  finally
    aLinkList.Free;
  end;
end;

function TAppServer.GetAllPictures: Variant;
var
  aPicList: TObjectList<TPicture>;
  aPic: TPicture;
  Doc: TDocVariantData;
begin
  TDocVariant.NewFast(Result);
  aPicList := aRestServer.RetrieveList<TPicture>();
  Doc.Init;
  try
    for aPic in aPicList do begin
      Doc.AddItem(_JsonFastFmt('{"picture":?}',[],[aPic.Picture]));
    end;
    _ObjAddProps(['pictures', Variant(Doc)], Result);
  finally
    aPicList.Free;
  end;

  if VarIsVoid(Result) then begin
    Result := _ObjFast(['error', 'No pictures found']);
  end;
  SQLite3Log.Add.Log(sllInfo, 'Result: %', [Result]);
end;


function TAppServer.GetAllWords: Variant;
var
  aWordList: TObjectList<TWord>;
  aWord: TWord;
  Doc: TDocVariantData;
begin
  TDocVariant.NewFast(Result);
  aWordList := aRestServer.RetrieveList<TWord>();
  Doc.Init;
  try
    for aWord in aWordList do begin
      Doc.AddItem(_JsonFastFmt('{"word":?,"english":?}',[],[aWord.Word, aWord.English]));
    end;
    _ObjAddProps(['words', Variant(Doc)], Result);
  finally
    aWordList.Free;
  end;

  if VarIsVoid(Result) then begin
    Result := _ObjFast(['error', 'No word found']);
  end;
  SQLite3Log.Add.Log(sllInfo, 'Result: %', [Result]);
end;

end.
