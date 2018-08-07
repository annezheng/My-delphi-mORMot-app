unit app_model;

interface

uses
  SynCommons,
  mORMot;

type
  TWord = class(TSQLRecordTimed)
  private
    fWord: RawUTF8;
    fEnglish: RawUTF8;
  published
    property Word: RawUTF8 read fWord write fWord;
    property English: RawUTF8 read fEnglish write fEnglish;
  end;

  TLink = class(TSQLRecordTimed)
  private
    fLink: RawUTF8;
    fDesp: RawUTF8;
  published
    property Link: RawUTF8 read fLink write fLink;
    property Desp: RawUTF8 read fDesp write fDesp;
  end;

  TPicture = class(TSQLRecordTimed)
  private
    fPicture: RawUTF8;
  published
    property Picture: RawUTF8 read fPicture write fPicture;
  end;

function CreateDataModel: TSQLModel;

const
  SERVER_ROOT = 'app';
  SERVER_PORT = '10720';

implementation

function CreateDataModel: TSQLModel;
begin
  Result := TSQLModel.Create([TWord, TLink, TPicture], SERVER_ROOT);
end;

end.
