program mORMotApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.ShlObj,
  Winapi.Windows,
  System.DateUtils,
  System.Generics.Collections,
  System.SysUtils,
  System.Win.Registry,
  SynCommons,
  SynLog,
  mORMot,
  mORMotSQLite3,
  SynSQLite3Static,
  mORMotHttpServer,
  app_model in 'app_model.pas',
  app_interface in 'app_interface.pas',
  app_server in 'app_server.pas',
  app_globals in 'app_globals.pas',
  app_view in 'app_view.pas';

var
  aModel: TSQLModel;
  aHttpServer: TSQLHttpServer;
  aFrontEnd: TFrontEnd;

procedure ClearWordTable;
begin
  aRestServer.Delete(TWord, ''); // no WHERE clause = delete all records
end;


procedure AddSampleWord(Client: TSQLRest);
var
  aWord: TWord;
begin
  aWord := TWord.Create;
  try
    aWord.Word := 'groen';
    aWord.English := 'green';
    Client.Add(aWord, True);

    aWord.Word := 'geel';
    aWord.English := 'yellow';
    Client.Add(aWord, True);

    aWord.Word := 'roze';
    aWord.English := 'pink';
    Client.Add(aWord, True);
  finally
    aWord.Free;
  end;
end;

begin
  try
//    SQLite3Log.Family.Level := LOG_VERBOSE;
    SQLite3Log.Family.Level := [sllException,sllExceptionOS];
    SQLite3Log.Family.EchoToConsole := LOG_VERBOSE;
    SQLite3Log.Family.PerThreadLog := ptIdentifiedInOnFile;

    aModel := CreateDataModel();
    try
      aRestServer := TSQLRestServerDB.Create(aModel, ChangeFileExt(ExeVersion.ProgramFileName, '.db3'));

      try
        aRestServer.CreateMissingTables();
        aFrontEnd := TFrontEnd.Create;
        try
          aFrontEnd.Start(aRestServer); // init web front-end
          aRestServer.ServiceDefine(TAppServer, [IAppServer], sicShared);
          aHttpServer := TSQLHttpServer.Create(SERVER_PORT, [aRestServer], '+', useHttpApiRegisteringURI);
          try
            aHttpServer.AccessControlAllowOrigin := '*';
            aHTTPServer.RootRedirectToURI(SERVER_ROOT + '/default');

//            AddSampleWord(aRestServer);
//            ClearWordTable();

            Writeln(#10'mORMot App Server is running.'#10);
            Writeln('Press [Enter] to stop the server.'#10);
            ConsoleWaitForEnterKey;

          finally
            aHttpServer.Free;
          end;
        finally
          aFrontEnd.Free;
        end;
      finally
        aRestServer.Free;
      end;
    finally
      aModel.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
