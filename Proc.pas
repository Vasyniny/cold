unit Proc;

interface
uses Windows, ExtCtrls, SysUtils, Graphics, Global, DB, StdCtrls, Variants, Forms, 
     CPort, Classes, Controls, Messages, JvLED, Buttons, JvEdit, ShellAPI, PsApi,
     JvXPButtons, ComCtrls, JvScrollBox, Dialogs;

function RealToStr(Number:real; W,D: Integer): String; // округление
function RealToStrLen(Number:real; W,D: Integer): String; // с округлением заданной длины
procedure ELpribBuildRequest(DeviceAddrELpr:Byte;StartAddrELpr,RegisterCountELpr:Word);


procedure ClearComponent(n:integer);


procedure MetakonCalculateCRC16(Fm:TByteMetakon; Len:integer); // контрольная сумма для Метакон
function numPosMet(add,chan:integer):integer; // номер позиции по адресу и каналу Метакона

procedure QuestMetakonTemp(Add,Chan:integer); // опрос Метакона температур
procedure RecordLOG(rec:string; flShow:boolean); // запись в LOG
procedure ParamsPSI(n:integer); // проверка наличия ПСИ для контр.точки
procedure ParamsXP(n:integer; fullCheck:boolean); // определяем параметры ХР по методике
procedure RaschetWch(n:integer); // расчет эл/эн
procedure CheckParamWch(n,nPoint:integer); // оценка расхода
procedure SaveParamIsp(n:integer); // сохранение параметров испытаний
procedure CheckParamWatt(n,nPoint:integer); // оценка мощности ХП
procedure ParamIspInScreen(n,nPoint:integer); // оценка и вывод параметров испытаний на экран
procedure DefinedOttaika(n:integer); // определение активной и пассивной оттайки для FNF
function ResTemptAllPoint(n,colPoint:integer; tt,pm:TArrReal; tpCh:boolean):boolean; // оценка результата температуры/мощности по всем контрольным точкам
function ResBlockAllPoint(n,colPoint:integer; res:TArrBool; tpCh:boolean):boolean; // оценка результата температуры по всем контрольным точкам
procedure ResultIsp(n,colPoint:integer; tpCh:boolean); // оценка результата испытания
procedure DefaultVar(n:integer); // обнуление переменных
procedure WriteDataInArr(n:integer); // запись значений мощности и температур в массивы
procedure DataInRecords(n:integer); // запись данных испытания в переменную Data
procedure WriteDataInFile(n:integer); // запись данных в файл
procedure DataIspPos(n:integer); // данные испытания на экран из файла
procedure proverkaDef;
procedure proverka(st:string); {проверка строки из пробелов}
function definePoint(n:integer):integer;  // определить на какой контр. точки для оценки рез-та
procedure ReturnPrevCode; // возврат предыдущего кода ХР при неудачном редактировании кода
procedure limitBlockXK(n,nPoint:integer); // вывод на экран параметров оценки блоков XK
procedure limitBlockMK(n,nPoint:integer); // вывод на экран параметров оценки блоков MK
function chPointToScreen(n,nPoint:integer; startStr:string):string; // вывод на экран ожидаемой контрольной точки
procedure ResultChPoinTempWtWtch(n,colPoint:integer; tpCh:boolean); // оценка Tхк,Тмк,Wt,Wtch на контрольной точке
procedure ELpribCalculateCRC16(data:TByteArray; Len:integer); //контр сумма для Эльприбор

procedure InitializeTestVars (i:integer);
procedure InitializeTestInterface (i:integer);

procedure RecordStartValueCheckPoint (i:integer);

procedure HandleUnSelectedModel (i:integer);
procedure HandleSelectedModel (i:integer);

procedure CheckCompressorOnState (i:integer);
procedure CheckCompressorOffState (i:integer);

procedure HandleFirstCompressorOff (i:integer);





implementation
uses Main, DataModule, Event, LstDef;

function RealToStr(Number:real; W,D: Integer): String; // с округлением
var st,Dec:string;
begin
  str(Number:W:D,st);
  if Pos('.',st)<>0 then
  begin
    Result:=copy(st,1,Pos('.',st)-1);
    Result:=Result+','+copy(st,Pos('.',st)+1,D);
  end else Result:=st;
  while Result[1]=' ' do delete(Result,1,1);
end;

function RealToStrLen(Number:real; W,D: Integer): String; // с округлением заданной длины
var st:string;
begin
  str(Number:W:D,st);
  if Pos('.',st)<>0 then begin
    Result:=copy(st,1,Pos('.',st)-1);
    Result:=Result+','+copy(st,Pos('.',st)+1,D);
  end else Result:=st;
//  while Result[1]=' ' do delete(Result,1,1);
end;

procedure ClearComponent(n:integer);
var nDev:integer; flDev:boolean;
begin
  case n of
    1..3: nDev:=1;    4..6: nDev:=2;    7..9: nDev:=3;    10..12: nDev:=4;
  end;
  flDev:=Dev.State[nDev];
  with fMain do begin
    with TLabel(FindComponent('lModel_'+IntToStr(n)))     do begin Caption:='Модель ХП'; Visible:=flDev; Enabled:=false; end;
    with TJvEdit(FindComponent('edKod_'+IntToStr(n)))     do begin Text:=''; ReadOnly:=false; Color:=clWindow; Visible:=flDev;  end;
    with TPanel(FindComponent('pCurTime_'+IntToStr(n)))   do begin Caption:=''; Visible:=flDev; end;
    with TLabel(FindComponent('lTime_'+IntToStr(n)))      do Caption:='';
    with TLabel(FindComponent('lChTm_'+IntToStr(n)))      do Visible:=false;
    with TLabel(FindComponent('lchPoint'+IntToStr(n)))    do Caption:='';
    with TPanel(FindComponent('pCurXK_'+IntToStr(n)))     do begin Caption:=''; Visible:=flDev; end;
    with TLabel(FindComponent('lmXK_'+IntToStr(n)))       do Caption:='';
    with TLabel(FindComponent('lispXK_'+IntToStr(n)))     do begin Caption:=''; Transparent:=true; end;
    with TPanel(FindComponent('pCurMK_'+IntToStr(n)))     do begin Caption:=''; Visible:=flDev; end;
    with TLabel(FindComponent('lmMK_'+IntToStr(n)))       do Caption:='';
    with TLabel(FindComponent('lispMK_'+IntToStr(n)))     do begin Caption:=''; Transparent:=true; end;
    with TJvLED(FindComponent('LedA_'+IntToStr(n)))       do begin Visible:=false; ColorOn:=clSilver; end;
    with TJvLED(FindComponent('LedP_'+IntToStr(n)))       do begin Visible:=false; ColorOn:=clSilver; end;
    with TPanel(FindComponent('pCurW_'+IntToStr(n)))      do begin Caption:=''; Visible:=flDev; end;
    with TLabel(FindComponent('lmW_'+IntToStr(n)))        do Caption:='';
    with TLabel(FindComponent('lispW_'+IntToStr(n)))      do begin Caption:=''; Transparent:=true; end;
    with TPanel(FindComponent('pCurWch_'+IntToStr(n)))    do begin Caption:=''; Visible:=flDev; end;
    with TLabel(FindComponent('lmWch_'+IntToStr(n)))      do Caption:='';
    with TLabel(FindComponent('lispWch_'+IntToStr(n)))    do begin Caption:=''; Transparent:=true; end;
    with TPanel(FindComponent('pCycl_'+IntToStr(n)))      do begin Caption:=''; Visible:=flDev; end;
    with TImage(FindComponent('ImgNoOff_'+IntToStr(n)))   do Visible:=false;
    with TPanel(FindComponent('pCurWH_'+IntToStr(n)))     do begin Caption:=''; Color:=$00DDF5FF; Visible:=flDev; end;
    with TImage(FindComponent('ImgH_'+IntToStr(n)))       do Visible:=false;
    with TLabel(FindComponent('lmWH_'+IntToStr(n)))       do Caption:='';
    with TJvScrollBox(FindComponent('scbBlock'+IntToStr(n))) do begin VertScrollBar.Position:=0; Enabled:=false; end;
    with TLabel(FindComponent('ltBlock_'+IntToStr(n)))    do Caption:='Показания';
    with TJvEdit(FindComponent('EdBlockXK_'+IntToStr(n))) do begin Text:=''; Color:=$00DDF5FF; ReadOnly:=true; Enabled:=false; Visible:=flDev; end;
    with TLabel(FindComponent('lmBlockXK_'+IntToStr(n)))  do Caption:='';
    with TUpDown(FindComponent('UpDwnXK'+IntToStr(n)))    do begin Enabled:=false; Visible:=flDev; end;
    with TJvEdit(FindComponent('EdBlockMK_'+IntToStr(n))) do begin Text:=''; Color:=$00DDF5FF; ReadOnly:=true; Enabled:=false; Visible:=flDev; end;
    with TLabel(FindComponent('lmBlockMK_'+IntToStr(n)))  do Caption:='';
    with TUpDown(FindComponent('UpDwnMK'+IntToStr(n)))    do begin Enabled:=false; Visible:=flDev; end;
    with TJvEdit(FindComponent('EdToffXK_'+IntToStr(n)))  do begin Text:=''; Color:=$00DDF5FF; ReadOnly:=true; Enabled:=false; Visible:=false; end;
    with TLabel(FindComponent('lmToffXK_'+IntToStr(n)))   do Caption:='';
    with TJvEdit(FindComponent('EdToffMK_'+IntToStr(n)))  do begin Text:=''; Color:=$00DDF5FF; ReadOnly:=true; Enabled:=false; Visible:=false; end;
    with TLabel(FindComponent('lmToffMK_'+IntToStr(n)))   do Caption:='';
    with TJvEdit(FindComponent('EdTonXK_'+IntToStr(n)))  do begin Text:=''; Color:=$00DDF5FF; ReadOnly:=true; Enabled:=false; Visible:=false; end;
    with TLabel(FindComponent('lmTonXK_'+IntToStr(n)))   do Caption:='';
    with TJvEdit(FindComponent('EdTonMK_'+IntToStr(n)))  do begin Text:=''; Color:=$00DDF5FF; ReadOnly:=true; Enabled:=false; Visible:=false; end;
    with TLabel(FindComponent('lmTonMK_'+IntToStr(n)))   do Caption:='';
    with TJvXPButton(FindComponent('BtnRes_'+IntToStr(n))) do begin Enabled:=false; Visible:=flDev; end;
    with TJvXPButton(FindComponent('BtnState_'+IntToStr(n))) do begin
      Glyph.LoadFromFile(MyDir+'Img\Gray.bmp'); Enabled:=false; Visible:=flDev;
    end;
    with TJvLED(FindComponent('ledEL'+IntToStr(n))) do Visible:=flDev;
    with TJvLED(FindComponent('ledMet'+IntToStr(n))) do Visible:=flDev;
    DefaultVar(n);
  end;
end;


procedure ELpribBuildRequest(DeviceAddrELpr:Byte;StartAddrELpr,RegisterCountELpr:Word);
var i:Byte;
begin
  RequestBufferELpr[0]:=DeviceAddrELpr;
  RequestBufferELpr[1]:=3;
  RequestBufferELpr[2]:=Hi(StartAddrELpr);
  RequestBufferELpr[3]:=lo(StartAddrELpr);
  RequestBufferELpr[4]:=Hi(RegisterCountELpr);
  RequestBufferELpr[5]:=lo(RegisterCountELpr);
  ELpribCalculateCRC16(RequestBufferELpr,6);
  RequestBufferELpr[6]:=Lo(crcELpr);
  RequestBufferELpr[7]:=Hi(crcELpr);
 //fMain.ELprib.ClearBuffer(True,true);
  fMain.ELprib.Write(RequestBufferELpr,8);
 { else ShowMessage('port is not open ');  }
  case DeviceAddrELpr of
    1: for i:=1 to 3 do with fMain do with TJvLED(FindComponent('ledEL'+IntToStr(i))) do ColorOn:=clYellow;
    2: for i:=4 to 6 do with fMain do with TJvLED(FindComponent('ledEL'+IntToStr(i))) do ColorOn:=clYellow;
    3: for i:=7 to 9 do with fMain do with TJvLED(FindComponent('ledEL'+IntToStr(i))) do ColorOn:=clYellow;
    4: for i:=10 to 11 do with fMain do with TJvLED(FindComponent('ledEL'+IntToStr(i))) do ColorOn:=clYellow;
  end;
end;


procedure MetakonCalculateCRC16(Fm:TByteMetakon; Len:integer); // контрольная сумма для Метакон
var i,j:integer;
begin
  CRC := $FF;                     //Инициализация контрольной суммы
  for I := 0 to Len-1 do begin      //Цикл по длине сообщения
    DAT := Fm[i];                      //Заполнение DAT символом из сообщения
    for J := 0 to 7 do begin           //Цикл по байту сообщения (8 бит в байте)
      AUX := (DAT xor CRC) and 1;         //Вычисление контрольной суммы:
      if AUX = 1 then CRC := CRC xor $18; // xor - Исключающее ИЛИ
      CRC := CRC shr 1;                   // and/or - Логическое И/ИЛИ
      CRC := CRC or (AUX shl 7);          // shl/shr - Сдвиг влево/вправо, не
      DAT := DAT shr 1;                   // циклический, без переноса-заема
    end;
  end; 
end;

function numPosMet(add,chan:integer):integer; // номер позиции по адресу и каналу Метакона
var n:integer;
begin
  case chan of
    0,1:  case add of 1: n:=1;
                      2: n:=4;
                      3: n:=7;
                      4: n:=10;
          end;
    2,3:  case add of 1: n:=2;  2: n:=5;  3: n:=8;  4: n:=11; end;
    4,5:  case add of 1: n:=3;  2: n:=6;  3: n:=9;  4: n:=12; end;
  end;
  Result:=n;
end;

procedure QuestMetakonTemp(Add,Chan:integer); // опрос Метакона температур
var st:string; i,k:integer;
begin
  if not fMain.Metakon.Connected then exit;
  st:=IntToStr(Add)+IntToStr(Chan)+'10'; LenStr:=Length(st);

        //   try AssignFile(fT1,'DataT1.dat'); Append(fT1);
        //   Write(fT1,'запрос: '+st); // Сохранение данных для отладки
        //   CloseFile(fT1);
        //   except CloseFile(fT1); end;

  for i:=1 to  LenStr do Frame[i-1]:=StrToInt(st[i]);
  MetakonCalculateCRC16(Frame,LenStr); Frame[LenStr]:=CRC;
  k:=fMain.Metakon.Write(Frame,LenStr+1);
    //
  with fMain do with TJvLED(FindComponent('ledMet' + IntToStr(numPosMet(Add,Chan)))) do ColorOn:=clYellow;
end;

procedure ELpribCalculateCRC16(data:TByteArray; Len:integer); //контр сумма для Эльприбор
var
  i,j:Integer;
begin
  crcELpr:=$ffff;
  for i:=0 to Len-1 do
  begin
    crcELpr:=crcELpr xor data[i];
    for j:=0 to 7 do
    begin
      if (crcELpr and 1)=1 then
      begin
        crcELpr:=(crcELpr shr 1) xor $a001;
      end
      else
      begin
        crcELpr:=crcELpr shr 1
      end;
    end;
  end;
end;

procedure RecordLOG(rec:string; flShow:boolean); // запись в LOG
var i:integer;
begin
  with fEvent.sgLOG do
  begin
    if not flPsw then RowCount:=RowCount+1;
    for i:=RowCount-1 downto 2 do
    begin
      Cells[0,i]:=Cells[0,i-1];
      Cells[1,i]:=Cells[1,i-1];
      Cells[2,i]:=Cells[2,i-1];
    end;
    Cells[0,1]:=DateToStr(Date);
    Cells[1,1]:=TimeToStr(Time);
    Cells[2,1]:=rec;
  end;
    // сохранение в БД
  dm.LOG.Append;
  dm.LOG['rDate']:=Date;
  dm.LOG['rTime']:=Time;
  dm.LOG['rRec']:=rec;
  dm.LOG['rUser']:=fMain.lUser.Caption;
  dm.LOG.CheckBrowseMode; dm.LOG.Close; dm.LOG.Open;
  if flShow then
    if not fEvent.Showing then fEvent.Show;
end;

procedure ParamsPSI(n:integer); // проверка наличия ПСИ для контр.точки
var nXP:integer; st:string;
begin
  nXP:=dm.spXP['idXP'];
    // параметры ПСИ по методике
  dm.qspPSI.Close; dm.qspPSI.Open;
  if dm.qspPSI.Locate('idXP',nXP,[loCaseInsensitive]) then
  begin
      // определение записи по Токр
    flParams[n]:=false;
    while not dm.qspPSI.Eof do
    begin
      if (Tokr>dm.qspPSI['Tokr1'])and(Tokr<=dm.qspPSI['Tokr2']) then
      begin
        flParams[n]:=true;
        if dm.qspPSI['Wtch']<>NULL then
        begin
          flWch[n,dm.checkTime.RecNo]:=true;
          pmWch[n,dm.checkTime.RecNo]:=dm.qspPSI['Wtch'];
        end
        else
        begin
          flWch[n,dm.checkTime.RecNo]:=false;
          pmWch[n,dm.checkTime.RecNo]:=0;
        end;
        break;
      end
      else dm.qspPSI.Next;
    end;
    if not flParams[n] then
    begin
      st:='Для модели "'+dm.spXP['Model']+'" в БД отсутствуют контролируемые параметры для Токр=';
      st:=st+RealToStr(Tokr,5,1)+'!';
      MessageDlgPos(st,mtWarning,[mbOk],0,{x}fMain.Left+250,{y}fMain.Top+350);
      flParams[n]:=false; {dm.qspPSI.Close;} exit;
    end;
  end
  else
  begin
    st:='Для модели "'+dm.spXP['Model']+'" в БД отсутствуют контролируемые параметры!';
    MessageDlgPos(st,mtWarning,[mbOk],0,{x}fMain.Left+250,{y}fMain.Top+350);
    flParams[n]:=false; //dm.qspPSI.Close;
  end;
end;

procedure ParamsXP(n:integer; fullCheck:boolean); // определяем параметры ХР по методике
var nXP,m,k,i:integer; BC,st,stH:string; state:boolean; hh,mm:word;
begin
  with fMain do
  begin
    if dm.spXP['TimeIsp']=NULL then
    begin
      st:='Для модели "'+dm.spXP['Model']+'" в БД отсутствует время проверки теплоэнергетических параметров!';
      MessageDlgPos(st,mtWarning,[mbOk],0,{x}fMain.Left+250,{y}fMain.Top+350);
      flParams[n]:=false; exit;
    end;
    dm.checkTime.Close; dm.checkTime.Open;
    if (dm.checkTime.RecordCount=0)or(dm.checkTime.RecordCount<>dm.spXP['nChPoint']) then
    begin
      st:='Для модели "'+dm.spXP['Model'];
      if dm.checkTime.RecordCount=0
        then st:=st+'" в БД отсутствует контрольное время снятия параметров!'
        else st:=st+'" в БД контрольное время снятия параметров указано не для всех контрольных точек!';
      MessageDlgPos(st,mtWarning,[mbOk],0,{x}fMain.Left+250,{y}fMain.Top+350);
      flParams[n]:=false; exit;
    end;
      // проверять по всем контрольным точкам или только по текущей
    if fullCheck
      then begin m:=1; k:=dm.checkTime.RecordCount; end
      else begin m:=nCheckPoint[n]; k:=m; end;

      // проверка наличия ПСИ для контр.точек
    for i:=m to k do
    begin
      dm.checkTime.RecNo:=i;
      flRangeXK[n,i]:=dm.checkTime['rangeXK']; flRangeMK[n,i]:=dm.checkTime['rangeMK'];
      CheckTime[n,i]:=dm.checkTime['chTime'];
      tpCheck[n,i]:=dm.checkTime['tpCheck'];
      ParamsPSI(n);
      if not flParams[n] then break;
    end;
    if flParams[n] then
    begin
      dm.checkTime.RecNo:=nCheckPoint[n]; colPoint[n]:=dm.spXP['nChPoint'];
      with TLabel(FindComponent('lchPoint'+IntToStr(n))) do
        if dm.checkTime.RecordCount=1 then Caption:=''
        else  Caption:=chPointToScreen(n,nCheckPoint[n], 'K:');
        // параметры ПСИ по методике
      dm.qspPSI.Close; dm.qspPSI.Open; nXP:=dm.spXP['idXP'];
      if dm.qspPSI.Locate('idXP',nXP,[loCaseInsensitive]) then
      begin
          // определение записи по Токр
        while not dm.qspPSI.Eof do
          if (Tokr>dm.qspPSI['Tokr1'])and(Tokr<=dm.qspPSI['Tokr2']) then break else dm.qspPSI.Next;
          // вывод на экран параметров
        with TLabel(FindComponent('lModel_' + IntToStr(n))) do begin Caption:=dm.spXP['Model']; Enabled:=true; end;
        if dm.spXP['TimeIsp']>200 then
        begin
          hh:=trunc(dm.spXP['TimeIsp']/60);
          mm:=dm.spXP['TimeIsp'] - hh*60;
          st:=IntToStr(hh)+'ч';
          if mm>0 then st:=st+IntToStr(mm)+'м';
        end
        else st:=IntToStr(dm.spXP['TimeIsp']);
        with TLabel(FindComponent('lTime_'+IntToStr(n))) do Caption:=st;
          //
        if dm.qspPSI['Txk']<>NULL then begin
          with TPanel(FindComponent('pCurXK_'+IntToStr(n))) do Visible:=true;
          with TLabel(FindComponent('lispXK_'+IntToStr(n))) do Visible:=true;
          with TLabel(FindComponent('lmXK_'+IntToStr(n))) do begin Caption:=RealToStr(dm.qspPSI['Txk'],5,1); Visible:=true; end;
          pmXK[n,nCheckPoint[n]]:=dm.qspPSI['Txk'];
        end
        else begin
          pmXK[n,nCheckPoint[n]]:=0;
          with TPanel(FindComponent('pCurXK_'+IntToStr(n))) do Visible:=false;
          with TLabel(FindComponent('lispXK_'+IntToStr(n))) do Visible:=false;
          with TLabel(FindComponent('lmXK_'+IntToStr(n))) do Visible:=false;
        end;
          //
        if dm.qspPSI['Tmk']<>NULL then begin
          with TPanel(FindComponent('pCurMK_'+IntToStr(n))) do Visible:=true;
          with TLabel(FindComponent('lispMK_'+IntToStr(n))) do Visible:=true;
          with TLabel(FindComponent('lmMK_'+IntToStr(n))) do begin Visible:=true; Caption:=RealToStr(dm.qspPSI['Tmk'],5,1); end;
          pmMK[n,nCheckPoint[n]]:=dm.qspPSI['Tmk'];
        end
        else begin
          pmMK[n,nCheckPoint[n]]:=0;
          with TPanel(FindComponent('pCurMK_'+IntToStr(n))) do Visible:=false;
          with TLabel(FindComponent('lispMK_'+IntToStr(n))) do Visible:=false;
          with TLabel(FindComponent('lmMK_'+IntToStr(n)))   do Visible:=false;
        end;
          //
        with TImage(FindComponent('ImgNoOff_'+IntToStr(n))) do Visible:=false;
        if dm.spXP['Method']='FnF' then begin // Full No Frost
          with TJvLED(FindComponent('LedA_'+IntToStr(n))) do Visible:=true;
          with TJvLED(FindComponent('LedP_'+IntToStr(n))) do Visible:=true;
        end
        else begin  // остальные ХП
          with TJvLED(FindComponent('LedA_'+IntToStr(n))) do Visible:=false;
          with TJvLED(FindComponent('LedP_'+IntToStr(n))) do Visible:=false;
        end;
          // мощность ХП
        if dm.qspPSI['Wt']<>NULL then begin
          with TPanel(FindComponent('pCurW_'+IntToStr(n))) do Visible:=true;
          with TLabel(FindComponent('lispW_'+IntToStr(n))) do Visible:=true;
          with TLabel(FindComponent('lmW_'+IntToStr(n))) do begin Visible:=true; Caption:=RealToStr(dm.qspPSI['Wt'],5,0); end;
          flW[n,nCheckPoint[n]]:=true; pmW[n,nCheckPoint[n]]:=dm.qspPSI['Wt'];
        end
        else begin
          flW[n,nCheckPoint[n]]:=false; pmW[n,nCheckPoint[n]]:=0;
          with TPanel(FindComponent('pCurW_'+IntToStr(n))) do Visible:=true; //false;
          with TLabel(FindComponent('lmW_'+IntToStr(n)))   do Visible:=false;
          with TLabel(FindComponent('lispW_'+IntToStr(n))) do Visible:=false;
        end;
          // расход э/энергии
//        if (dm.qspPSI['Wtch']<>NULL)and(dm.qspPSI['Wtch']<>0) then begin
        state:=false;
        if flWch[n,nCheckPoint[n]] then k:=nCheckPoint[n]
        else begin
          for i:=nCheckPoint[n] downto 1 do
            if flWch[n,i] then begin k:=i; break; end;
        end;
        if flWch[n,k] then begin
            state:=true;
            with TLabel(FindComponent('lmWch_'+IntToStr(n))) do begin Caption:=RealToStr(pmWch[n,k],3,0); Visible:=true; end;
        end;
        if state then begin //dm.qspPSI['Wtch']<>NULL
          with TPanel(FindComponent('pCurWch_'+IntToStr(n))) do Visible:=true;
          with TLabel(FindComponent('lispWch_'+IntToStr(n))) do Visible:=true;
//          with TLabel(FindComponent('lmWch_'+IntToStr(n))) do begin Caption:=RealToStr(dm.spPSI['Wtch'],5,0); Visible:=true; end;
//          flIspWch[n]:=true; pmWch[n]:=dm.spPSI['Wtch'];
        end
        else begin
//          flIspWch[n]:=false; pmWch[n]:=0;
          with TPanel(FindComponent('pCurWch_'+IntToStr(n))) do Visible:=false;
          with TLabel(FindComponent('lispWch_'+IntToStr(n))) do Visible:=false;
          with TLabel(FindComponent('lmWch_'+IntToStr(n)))   do Visible:=false;
        end;
          //
        if dm.spXP['wSumm']<>'0' then begin
          with TPanel(FindComponent('pCurWH_'+IntToStr(n))) do Visible:=true;
          with TImage(FindComponent('ImgH_'+IntToStr(n))) do Visible:=true;
          with TLabel(FindComponent('lmWH_'+IntToStr(n))) do begin
            Visible:=true; chSumm[n]:=false;
            chSumm[n]:=true; st:=dm.spXP['wSumm'];
            if (copy(st,1,Pos('-',st)-1)<>'M')and(copy(st,1,Pos('-',st)-1)<>'L') then begin
              Caption:=dm.spXP['wSumm'];
              st:=Caption; st:=copy(st,1,Pos('.',st)-1); pmWHmin[n]:=StrToInt(st);
              st:=Caption; st:=copy(st,Pos('-',st)+2,Length(st)-Pos('-',st)); pmWHmax[n]:=StrToInt(st);
            end
            else begin
              stH:=copy(st,Pos('-',st)+1,Length(st)-Pos('-',st));
              if copy(st,1,Pos('-',st)-1)='M' then begin // не менее (>=)
                Caption:=#179+' '+stH; pmWHmin[n]:=StrToInt(stH); pmWHmax[n]:=1000;
              end;
              if copy(st,1,Pos('-',st)-1)='L' then begin // не более (<=)
                Caption:=#163+' '+stH; pmWHmin[n]:=0; pmWHmax[n]:=StrToInt(stH);
              end;
            end;
          end;
        end
        else begin
          chSumm[n]:=false;
          with TPanel(FindComponent('pCurWH_'+IntToStr(n))) do Visible:=false;
          with TImage(FindComponent('ImgH_'+IntToStr(n))) do Visible:=false;
          with TLabel(FindComponent('lmWH_'+IntToStr(n)))   do Visible:=false;
        end;
          //
        if dm.spXP['ToffXK']=NULL then begin chToffXK[n]:=false; pmToffXK[n]:=0; end
        else begin
          chToffXK[n]:=true; pmToffXK[n]:=dm.spXP['ToffXK'];
          with TLabel(FindComponent('lmToffXK_'+IntToStr(n))) do Caption:=RealToStr(dm.spXP['ToffXK'],5,1)+#177+'0,3';
        end;
        with TJvEdit(FindComponent('EdToffXK_'+IntToStr(n))) do Visible:=chToffXK[n];
        with TLabel(FindComponent('lmToffXK_'+IntToStr(n))) do Visible:=chToffXK[n];
          //
        if dm.spXP['ToffMK']=NULL then begin chToffMK[n]:=false; pmToffMK[n]:=0; end
        else begin
          chToffMK[n]:=true; pmToffMK[n]:=dm.spXP['ToffMK'];
          with TLabel(FindComponent('lmToffMK_'+IntToStr(n))) do Caption:=RealToStr(dm.spXP['ToffMK'],5,1)+#177+'0,3';
        end;
        with TJvEdit(FindComponent('EdToffMK_'+IntToStr(n))) do Visible:=chToffMK[n];
        with TLabel(FindComponent('lmToffMK_'+IntToStr(n))) do Visible:=chToffMK[n];
          //
        if dm.spXP['TonXK']=NULL then begin chTonXK[n]:=false; pmTonXK[n]:=0; end
        else begin
          chTonXK[n]:=true; pmTonXK[n]:=dm.spXP['TonXK'];
          with TLabel(FindComponent('lmTonXK_'+IntToStr(n))) do Caption:=RealToStr(dm.spXP['TonXK'],5,1)+#177+'0,3';
        end;
        with TJvEdit(FindComponent('EdTonXK_'+IntToStr(n))) do Visible:=chTonXK[n];
        with TLabel(FindComponent('lmTonXK_'+IntToStr(n))) do Visible:=chTonXK[n];
          //
        if dm.spXP['TonMK']=NULL then begin chTonMK[n]:=false; pmTonMK[n]:=0; end
        else begin
          chTonMK[n]:=true; pmTonMK[n]:=dm.spXP['TonMK'];
          with TLabel(FindComponent('lmTonMK_'+IntToStr(n))) do Caption:=RealToStr(dm.spXP['TonMK'],5,1)+#177+'0,3';
        end;
        with TJvEdit(FindComponent('EdTonMK_'+IntToStr(n))) do Visible:=chTonMK[n];
        with TLabel(FindComponent('lmTonMK_'+IntToStr(n))) do Visible:=chTonMK[n];
          // блок ХК
        chBlockXK[n]:=dm.spXP['BlockXK'];
        with TJvEdit(FindComponent('EdBlockXK_'+IntToStr(n))) do Visible:=chBlockXK[n];
        with TUpDown(FindComponent('UpDwnXK'+IntToStr(n)))   do Visible:=chBlockXK[n];
          //
        if (dm.checkTime['dopBlockXK']<>NULL)or(dm.checkTime['rangeXK']) then begin
          if dm.checkTime['rangeXK'] then begin
            pmRangeXK[n,nCheckPoint[n],1]:=dm.qspPSI['maxRangeXK'];
            pmRangeXK[n,nCheckPoint[n],2]:=dm.qspPSI['minRangeXK'];
          end
          else pmDopBlXK[n]:=dm.checkTime['dopBlockXK'];
          limitBlockXK(n,nCheckPoint[n]);
        end
        else begin
          pmDopBlXK[n]:=0;
          with TLabel(FindComponent('lmBlockXK_'+IntToStr(n))) do Visible:=false;
        end;
          // Блок МК
        chBlockMK[n]:=dm.spXP['BlockMK'];
        with TJvEdit(FindComponent('EdBlockMK_'+IntToStr(n))) do Visible:=chBlockMK[n];
        with TUpDown(FindComponent('UpDwnMK'+IntToStr(n)))   do Visible:=chBlockMK[n];
          //
        if (dm.checkTime['dopBlockMK']<>NULL)or(dm.checkTime['rangeMK']) then
        begin
          if dm.checkTime['rangeMK'] then begin
            pmRangeMK[n,nCheckPoint[n],1]:=dm.qspPSI['maxRangeMK'];
            pmRangeMK[n,nCheckPoint[n],2]:=dm.qspPSI['minRangeMK'];
          end
          else pmDopBlMK[n]:=dm.checkTime['dopBlockMK'];
          limitBlockMK(n,nCheckPoint[n]);
        end
        else
        begin
          pmDopBlMK[n]:=0;
          with TLabel(FindComponent('lmBlockMK_'+IntToStr(n))) do Visible:=false;
        end;
          //
        TypeXP[n]:=dm.spXP['tip']; KodXP[n]:=dm.spXP['kod']; chMetod[n]:=dm.spXP['Method'];
        TimeIsp[n]:=dm.spXP['TimeIsp']; chOffCmp[n]:=dm.spXP['CheckOff'];bgChTm[n]:=dm.spXP['bgChTm'];
      end;
    end;
  end;
end;

procedure RaschetWch(n:integer); // расчет эл/эн
var hh,mm,ss,ms:word; tm:TDateTime; tPeriod:real; k:integer;
begin
{  if not flWch[n,k] then begin
    flWch[n,nPoint]:=true; ttWch[n,nPoint]:=0;
    TmrPerW[n,1]:=Now; TmrPerW[n,2]:=TmrPerW[n,1];
  end
  else begin }
    TmrPerW[n,1]:=TmrPerW[n,2]; TmrPerW[n,2]:=Now;
    tm:=TmrPerW[n,2]-TmrPerW[n,1];
    DecodeTime(tm,hh,mm,ss,ms); tPeriod:=hh+mm/60+ss/3600+((ms/1000)/60)/60;
    curWch[n]:=curWch[n]+(valW[n]*tPeriod);
//  end;
  with fMain do with TPanel(FindComponent('pCurWch_'+IntToStr(n))) do
    Caption:=RealToStr(curWch[n],5,0);
end;

procedure SaveParamIsp(n:integer); // сохранение параметров испытаний В ПЕРЕМЕННЫЕ tt
var tm:TDateTime; hh,mm,ss,ms:word; i:integer;
begin
  flSavePar[n,nCheckPoint[n]]:=true;
  nChTemp[n,nCheckPoint[n]]:=NumVal[n]-3; // № контрольного сигнала температуры
  if (TypeXP[n]='хм')or(TypeXP[n]='хк')or(TypeXP[n]='мм')or(TypeXP[n]='хх') then begin // ХК
    ttXK[n,nCheckPoint[n]]:=arrXK[n,NumVal[n]-3];
  end;
  if (TypeXP[n]='хм')or(TypeXP[n]='мк')or(TypeXP[n]='мм')or(TypeXP[n]='хх') then begin  // МК
    ttMK[n,nCheckPoint[n]]:=arrMK[n,NumVal[n]-3];
  end;
  if flW[n,nCheckPoint[n]] then  // мощность ХП
    if ((nCheckPoint[n]=1)and(not wCmp[n])) or (nCheckPoint[n]>1) then begin
//    if (chMetod[n]<>'End')or((chMetod[n]='End')and(not wCmp[n])) then begin
      ttW[n,nCheckPoint[n]]:=arrW[n,NumVal[n]-3]; nChW[n,nCheckPoint[n]]:=NumVal[n]-3;
    end;
end;

procedure CheckParamWatt(n,nPoint:integer); // оценка мощности ХП
var flOkr:boolean; T:real;
begin
  with fMain do begin
      // уточнение оценочных характеристик по средней Токр
    T:=(bgnTokr[n]+Tokr)/2;
    dm.spXP.Close; dm.spXP.Open; dm.spXP.Locate('kod',KodXP[n],[loCaseInsensitive]);
      // параметры по методике
    dm.checkTime.Open; dm.checkTime.RecNo:=nCheckPoint[n];
    dm.qspPSI.Open; dm.qspPSI.First;
      // определение записи по Токр
    flOkr:=false;
    while not dm.qspPSI.Eof do begin
      if (T>dm.qspPSI['Tokr1'])and(T<=dm.qspPSI['Tokr2']) then begin flOkr:=true; break; end else dm.qspPSI.Next;
    end;
    if not flOkr then begin // берем характеристики либо по нижней границе либо по верхней
      if T>dm.qspPSI['Tokr2'] then dm.qspPSI.Last else dm.qspPSI.First;
    end;
      // вывод на экран обновленной характеристики
    with TLabel(FindComponent('lmW_'+IntToStr(n))) do Caption:=RealToStr(dm.qspPSI['Wt'],5,0);
    pmW[n,nPoint]:=dm.qspPSI['Wt'];
    //dm.qspPSI.Close;
      // оценка мощности ХП
    with TLabel(FindComponent('lispW_'+IntToStr(n))) do begin
      Caption:=RealToStr(ttW[n,nPoint],5,0); Transparent:=false;
      if ttW[n,nPoint]<=pmW[n,nPoint] then Color:=$00ACF471 else Color:=$00947DEC;
    end;
  end;
end;

procedure CheckParamWch(n,nPoint:integer); // оценка расхода
begin
  with fMain do with TLabel(FindComponent('lispWch_'+IntToStr(n))) do begin
    Caption:=RealToStr(ttWch[n,nPoint],5,0); Transparent:=false;
    if ttWch[n,nPoint]<=pmWch[n,nPoint] then Color:=$00ACF471 else Color:=$00947DEC;
  end;
end;

procedure ParamIspInScreen(n,nPoint:integer); // вывод параметров испытаний на экран
var T:real; flOkr:boolean;
begin
    // уточнение оценочных характеристик по средней Токр
  T:=(bgnTokr[n]+endTokr[n,nPoint])/2;
  dm.spXP.Open; dm.spXP.Locate('kod',KodXP[n],[loCaseInsensitive]);
    // текущая контрольная точка
  dm.checkTime.Close; dm.checkTime.Open; dm.checkTime.RecNo:=nPoint;
  flRangeXK[n,nPoint]:=dm.checkTime['rangeXK']; flRangeMK[n,nPoint]:=dm.checkTime['rangeMK'];
    // параметры по методике
  dm.qspPSI.Close; dm.qspPSI.Open; dm.qspPSI.First;
    // определение записи по Токр
  flOkr:=false;
  while not dm.qspPSI.Eof do begin
    if (T>dm.qspPSI['Tokr1'])and(T<=dm.qspPSI['Tokr2']) then begin flOkr:=true; break; end else dm.qspPSI.Next;
  end;
  if not flOkr then begin // берем характеристики либо по нижней границе либо по верхней
    if T>dm.qspPSI['Tokr2'] then dm.qspPSI.Last else dm.qspPSI.First;
  end;
    //
  with fMain do begin
    if dm.qspPSI['Txk']<>NULL then begin
      with TLabel(FindComponent('lmXK_'+IntToStr(n))) do Caption:=RealToStr(dm.qspPSI['Txk'],5,1);
      pmXK[n,nPoint]:=dm.qspPSI['Txk'];
    end;
      //
    if dm.qspPSI['Tmk']<>NULL then begin
      with TLabel(FindComponent('lmMK_'+IntToStr(n))) do Caption:=RealToStr(dm.qspPSI['Tmk'],5,1);
      pmMK[n,nPoint]:=dm.qspPSI['Tmk'];
    end;
      //
    if dm.qspPSI['Wt']<>NULL then begin
//      if (chMetod[n]<>'End')or((chMetod[n]='End')and(not wCmp[n])) then begin
      with TLabel(FindComponent('lmW_'+IntToStr(n))) do Caption:=RealToStr(dm.qspPSI['Wt'],5,0);
      pmW[n,nPoint]:=dm.qspPSI['Wt'];
    end;
      //
    if dm.qspPSI['Wtch']<>NULL then begin
      with TLabel(FindComponent('lmWch_'+IntToStr(n))) do Caption:=RealToStr(dm.qspPSI['Wtch'],5,0);
      pmWch[n,nPoint]:=dm.qspPSI['Wtch'];
    end;
  end;
    // Блок ХК
  if (dm.checkTime['dopBlockXK']<>NULL)or(dm.checkTime['rangeXK']) then begin
    if dm.checkTime['rangeXK'] then begin
      pmRangeXK[n,nPoint,1]:=dm.qspPSI['maxRangeXK'];
      pmRangeXK[n,nPoint,2]:=dm.qspPSI['minRangeXK'];
    end
    else pmDopBlXK[n]:=dm.checkTime['dopBlockXK'];
    limitBlockXK(n,nPoint);
  end
  else begin
    pmDopBlXK[n]:=0;
    with fMain do with TLabel(FindComponent('lmBlockXK_'+IntToStr(n))) do Visible:=false;
  end;
    // Блок MК
  if (dm.checkTime['dopBlockMK']<>NULL)or(dm.checkTime['rangeMK']) then begin
    if dm.checkTime['rangeMK'] then begin
      pmRangeMK[n,nPoint,1]:=dm.qspPSI['maxRangeMK'];
      pmRangeMK[n,nPoint,2]:=dm.qspPSI['minRangeMK'];
    end
    else pmDopBlMK[n]:=dm.checkTime['dopBlockMK'];
    limitBlockMK(n,nPoint);
  end
  else begin
    pmDopBlMK[n]:=0;
    with fMain do with TLabel(FindComponent('lmBlockMK_'+IntToStr(n))) do Visible:=false;
  end;
    //
  //dm.qspPSI.Close; dm.spXP.Close;

    // оценка параметров
  with fMain do begin
    if (TypeXP[n]='хм')or(TypeXP[n]='хк')or(TypeXP[n]='мм')or(TypeXP[n]='хх') then begin // ХК
      with TLabel(FindComponent('lispXK_'+IntToStr(n))) do begin
        Caption:=RealToStr(ttXK[n,nPoint],5,1); Transparent:=false;
        if ttXK[n,nPoint]<=pmXK[n,nPoint] then Color:=$00ACF471 else Color:=$00947DEC;
      end;
    end;
    if (TypeXP[n]='хм')or(TypeXP[n]='мк')or(TypeXP[n]='мм')or(TypeXP[n]='хх') then begin // МК
      with TLabel(FindComponent('lispMK_'+IntToStr(n))) do begin
        Caption:=RealToStr(ttMK[n,nPoint],5,1); Transparent:=false;
        if ttMK[n,nPoint]<=pmMK[n,nPoint] then Color:=$00ACF471 else Color:=$00947DEC;
      end;
    end;
      // мощность ХП
    if flW[n,nPoint] then CheckParamWatt(n,nPoint);
  end;
end;

procedure DefinedOttaika(n:integer); // определение активной и пассивной оттайки для FNF
var tmWA:integer; hh,mm,ss,ms:word;
begin
  with fMain do begin
    if (chMetod[n]='FnF')and(not flWork2[n]) then begin
        // вычисление времени, прошедшего после первого включения
      if (flWork1[n])and(not flActive[n]) then begin
        DecodeTime((Now-tmOnWork1[n]),hh,mm,ss,ms);
        tmWA:=hh*3600+mm*60+ss; // в секундах
          // если после первого включения прошло более 15 секунд, ожидаем активную оттайку
        if tmWA>15 then begin
          if (arrW[n,NumVal[n]-1]-arrW[n,NumVal[n]-2])>UstW{*1.5} then begin
            flActive[n]:=true; tmOnWork1[n]:=Now;
            with TJvLED(FindComponent('LedA_'+IntToStr(n))) do ColorOn:=clLime;
                      //    AssignFile(fW3,'DataW3.dat'); Append(fW3);writeln(fW3);
                     //    writeln(fW3,'active   Wn='+RealToStr(curW[i,j,NumCurW[i,j]-1],5,1)+'  Wn-2='+RealToStr(curW[i,j,NumCurW[i,j]-3],5,1));
                     //    writeln(fW3);CloseFile(fW3);
             exit;
          end;
            // если компрессор отключился до активной оттайки, то оттайки не отслеживаем и flWork2:=true
          if arrW[n,NumVal[n]-1]<UstW then begin
            flWork2[n]:=true; Inc(numOnCmp[n]);
            with TJvLED(FindComponent('LedA_'+IntToStr(n))) do ColorOn:=clRed;
            with TJvLED(FindComponent('LedP_'+IntToStr(n))) do ColorOn:=clRed;
            exit;
          end;
        end;
      end;
      if (flActive[n])and(not flPassive[n]) then begin
        DecodeTime((Now-tmOnWork1[n]),hh,mm,ss,ms);
        tmWA:=hh*3600+mm*60+ss; // в секундах
        if (arrW[n,NumVal[n]-1])<UstW{>UstW*4} then begin
            // проверка на ложную активную оттайку - если пассивная оттайка наступила слишком быстро
            // если с начала активной оттайки прошло более 1 минуты - значит это пассивная оттайка
          if tmWA>60 then begin
            flPassive[n]:=true;
            with TJvLED(FindComponent('LedP_'+IntToStr(n))) do ColorOn:=clLime;
                    //     AssignFile(fW3,'DataW3.dat'); Append(fW3); writeln(fW3);
                    //     writeln(fW3,'passive   Wn-2='+RealToStr(curW[i,j,NumCurW[i,j]-3],5,1)+'  Wn='+RealToStr(curW[i,j,NumCurW[i,j]-1],5,1));
                    //     writeln(fW3); CloseFile(fW3);
            exit;
          end
          else begin // ложная пассивная оттайка
            flWork2[n]:=true; Inc(numOnCmp[n]);
            with TJvLED(FindComponent('LedA_'+IntToStr(n))) do ColorOn:=clRed;
            with TJvLED(FindComponent('LedP_'+IntToStr(n))) do ColorOn:=clRed;
            exit;
          end;
        end;
          // проверка на повторную активную оттайку
          // если после первой оттайки прошло более 15 секунд, проверяем на повторную активную оттайку
        if tmWA>15 then begin
          if (arrW[n,NumVal[n]-1]-arrW[n,NumVal[n]-2])>UstW{*1.5} then begin
            flWork2[n]:=true; Inc(numOnCmp[n]);
            with TJvLED(FindComponent('LedP_'+IntToStr(n))) do ColorOn:=clRed;
            exit;
          end;
        end;
      end;
      if (flPassive[n])and(not flWork2[n]) then
        if (arrW[n,NumVal[n]-1])>UstW then begin
          flWork2[n]:=true;
                     //   AssignFile(fW3,'DataW3.dat'); Append(fW3); writeln(fW3);
                    //   writeln(fW3,'work2   Wn='+RealToStr(curW[i,j,NumCurW[i,j]-1],5,1)+'  Wn-2='+RealToStr(curW[i,j,NumCurW[i,j]-3],5,1));
                    //   writeln(fW3); CloseFile(fW3);
           exit;  
        end;
    end;
  end;
end;

function ResTemptAllPoint(n,colPoint:integer; tt,pm:TArrReal; tpCh:boolean):boolean; // оценка результата температуры/мощности по всем контрольным точкам
var i:integer;
begin
  Result:=true;
  for i:=1 to colPoint do
  begin
    if (tpCheck[n,i]) or ((not tpCheck[n,i])and(tpCh)) then
      Result:= Result and (tt[n,i] <= pm[n,i]);
  end;
end;

function ResBlockAllPoint(n,colPoint:integer; res:TArrBool; tpCh:boolean):boolean; // оценка результата температуры по всем контрольным точкам
var i:integer;
begin
  Result:=true;
  for i:=1 to colPoint do begin
    if (tpCheck[n,i]) or((not tpCheck[n,i])and(tpCh)) then
      Result:= Result and res[n,i];
  end;
end;

procedure ResultIsp(n,colPoint:integer; tpCh:boolean); // оценка результата испытания
var flRes,state:boolean; i:integer; st:string;
begin
  flRes:=true; KodBrak[n]:='';
    // оценка наличия этапов "full no frost"
  if flRes then
  begin
    if chMetod[n]='FnF' then
      if ((not flWork1[n])or(not flActive[n])or(not flPassive[n])or(not flWork2[n])) then begin
        flRes:=false;
        if (not flActive[n])and(not flPassive[n]) then KodBrak[n]:='72' // нет активной и пассивной оттайки
        else
          if not flActive[n] then KodBrak[n]:='70' // нет активной оттайки
          else KodBrak[n]:='71' // нет пассивной оттайки
      end;
  end;
    // оценка температуры в ХК и МК
  if flRes then begin
    if ((TypeXP[n]='хм')or(TypeXP[n]='хк')or(TypeXP[n]='мм')or(TypeXP[n]='хх'))and(not ResTemptAllPoint(n,colPoint,ttXK,pmXK,tpCh)) then flRes:=false;
    if ((TypeXP[n]='хм')or(TypeXP[n]='мк')or(TypeXP[n]='мм')or(TypeXP[n]='хх'))and(not ResTemptAllPoint(n,colPoint,ttMK,pmMK,tpCh)) then flRes:=false;
    if not flRes then begin
      if (TypeXP[n]='хк')and(not ResTemptAllPoint(n,colPoint,ttXK,pmXK,tpCh)) then begin
        if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+','; KodBrak[n]:=KodBrak[n]+'11'; // завышена температура в ХК
      end
      else
        if (TypeXP[n]='мк')and(not ResTemptAllPoint(n,colPoint,ttMK,pmMK,tpCh)) then begin
          if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+','; KodBrak[n]:=KodBrak[n]+'12'; // завышена температура в MК
        end
        else // хм и мм и хх
          if (not ResTemptAllPoint(n,colPoint,ttXK,pmXK,tpCh))and(not ResTemptAllPoint(n,colPoint,ttMK,pmMK,tpCh)) then begin
            if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+','; KodBrak[n]:=KodBrak[n]+'10'; // завышена температура в ХК и MК
          end
          else begin
            if not ResTemptAllPoint(n,colPoint,ttXK,pmXK,tpCh) then begin
              if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+','; KodBrak[n]:=KodBrak[n]+'11'; // завышена температура в ХК
            end;
            if not ResTemptAllPoint(n,colPoint,ttMK,pmMK,tpCh) then begin
              if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+','; KodBrak[n]:=KodBrak[n]+'12'; // завышена температура в MК
            end;
          end;
    end;
  end;
    // оценка мощности нагревателя/суммарной мощности
  if (chSumm[n])and((ttWH[n]<pmWHmin[n])or(ttWH[n]>pmWHmax[n])) then begin
    flRes:=false;
    if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+',';
    if ttWH[n]<pmWHmin[n] then begin
      if chSumm[n] then KodBrak[n]:=KodBrak[n]+'34'; // занижена суммарная мощность
    end;
    if ttWH[n]>pmWHmax[n] then begin
      if chSumm[n] then KodBrak[n]:=KodBrak[n]+'35'; // завышена суммарная мощность
    end;
  end;
    // оценка показаний блоков ХК
  if chBlockXK[n] then begin
    if not ResBlockAllPoint(n,colPoint,resBlockXK,tpCh) then begin
      if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; KodBrak[n]:=KodBrak[n]+'80'; // показания блока не по КД
    end;
  end;
    // оценка показаний блоков MК
  if chBlockMK[n] then begin
    if not ResBlockAllPoint(n,colPoint,resBlockMK,tpCh) then begin
      if (Length(KodBrak[n])>0)and(Pos('80',KodBrak[n])=0) then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; if Pos('80',KodBrak[n])=0 then KodBrak[n]:=KodBrak[n]+'80'; // показания блока не по КД
    end;
  end;
    // если предыдущие дефекты не обнаружены, тогда оцениваем следующие
//  if flRes then begin
      // оценка мощности ХП
    state:=false;
    for i:=1 to colPoint do state:= state or flW[n,i];
    if (state)and(not ResTemptAllPoint(n,colPoint,ttW,pmW,tpCh)) then begin
      if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; KodBrak[n]:=KodBrak[n]+'30'; // завышена мощность ХП
    end;
      // оценка расхода эл/энергии
    state:=false;
    for i:=1 to colPoint do state:= state or flWch[n,i];
    if (state)and(not ResTemptAllPoint(n,colPoint,ttWch,pmWch,tpCh)) then begin
      if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; KodBrak[n]:=KodBrak[n]+'36'; // завышен расход эл/эн.
    end;
      // проверка отключения компрессора
    if (chOffCmp[n])and(not ttCmp[n]) then begin
      if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; KodBrak[n]:=KodBrak[n]+'96'; // не отключается м/к
    end;
      // оценка температуры откл. компрессора
    if (chToffXK[n])and(Abs(ttToffXK[n]-pmToffXK[n])>0.3) then begin
      if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; KodBrak[n]:=KodBrak[n]+'81'; // Тоткл м/к не по КД
    end;
    if (chToffMK[n])and(Abs(ttToffMK[n]-pmToffMK[n])>0.3) then begin
      if (Length(KodBrak[n])>0)and(Pos('81',KodBrak[n])=0)then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; if Pos('81',KodBrak[n])=0 then KodBrak[n]:=KodBrak[n]+'81'; // Тоткл м/к не по КД
    end;
      // оценка температуры вкл. компрессора
    if (chTonXK[n])and(Abs(ttTonXK[n]-pmTonXK[n])>0.3) then begin
      if Length(KodBrak[n])>0 then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; KodBrak[n]:=KodBrak[n]+'81'; // Тоткл м/к не по КД
    end;
    if (chTonMK[n])and(Abs(ttTonMK[n]-pmTonMK[n])>0.3) then begin
      if (Length(KodBrak[n])>0)and(Pos('81',KodBrak[n])=0)then KodBrak[n]:=KodBrak[n]+',';
      flRes:=false; if Pos('81',KodBrak[n])=0 then KodBrak[n]:=KodBrak[n]+'81'; // Тоткл м/к не по КД
    end;
//  end;
    //
  with fMain do begin
      // список обнаруженных дефектов
//    with TPanel(FindComponent('pKodBr_'+IntToStr(n))) do Caption:=KodBrak[n];
    with TJvXPButton(FindComponent('BtnRes_'+IntToStr(n))) do Enabled:=true;

  end;
  ResIsp[n]:=flRes;
end;

procedure DefaultVar(n:integer); // обнуление переменных
var i,k:integer;
begin
  StatePos[n]:=0; KodBrak[n]:=''; ResIsp[n]:=false; flParams[n]:=false; 
  NumVal[n]:=0; SetLength(arrW[n],0); SetLength(arrXK[n],0); SetLength(arrMK[n],0);
  for i:=1 to 7 do begin
    flSavePar[n,i]:=false; pmXK[n,i]:=0; ttXK[n,i]:=0; nChTemp[n,i]:=0; pmMK[n,i]:=0; ttMK[n,i]:=0;
    pmWch[n,i]:=0; flWch[n,i]:=false; ttWch[n,i]:=0; ttBlockXK[n,i]:=0; ttBlockMK[n,i]:=0;
    flBlockXK[n,i]:=false; flBlockMK[n,i]:=false; CheckTime[n,i]:=0; endTokr[n,i]:=0;
    flRangeXK[n,i]:=false; flRangeMK[n,i]:=false; pmW[n,i]:=0; ttW[n,i]:=0; flW[n,i]:=false; nChW[n,i]:=0;
  end;
  for k:=1 to 7 do for i:=1 to 2 do begin pmRangeXK[n,k,i]:=0; pmRangeMK[n,k,i]:=0; end;
  numOff[n]:=0; wCmp[n]:=false; ttCmp[n]:=false;
  chSumm[n]:=false; flSumm[n]:=false; pmWHmin[n]:=0; nCheckPoint[n]:=1;
  pmWHmax[n]:=0; ttWH[n]:=0; chToffXK[n]:=false; chToffMK[n]:=false;
  pmToffXK[n]:=0; pmToffMK[n]:=0; chBlockXK[n]:=false;
  chBlockMK[n]:=false; flToffXK[n]:=false; bgnWch[n]:=0; curWch[n]:=0;
  flToffMK[n]:=false; ttToffXK[n]:=0; ttToffMK[n]:=0; pmDopBlXK[n]:=0; pmDopBlMK[n]:=0;
  TypeXP[n]:=''; KodXP[n]:=''; mmCur[n]:=0; chMetod[n]:=''; tmOnWork1[n]:=0; flWork1[n]:=false;
  flActive[n]:=false; flPassive[n]:=false; flWork2[n]:=false; TimeIsp[n]:=0;
  tmStart[n]:=0; flOnCmp[n]:=false; numOnCmp[n]:=0; numOffCmp[n]:=0;
  TimeOffCmp[n]:=0; chOffCmp[n]:=false; bgChTm[n]:=false; bgnTokr[n]:=0;
  TimeAllIsp[n]:=0; chTonXK[n]:=false; chTonMK[n]:=false;
  pmTonXK[n]:=0; pmTonMK[n]:=0; flTonXK[n]:=false; flTonMK[n]:=false;
end;

procedure WriteDataInArr(n:integer); // запись значений мощности и температур в массивы
begin
  Inc(NumVal[n]);
  SetLength(arrW[n],NumVal[n]); arrW[n,NumVal[n]-1]:=valW[n]; // массив мощности
  SetLength(arrXK[n],NumVal[n]); arrXK[n,NumVal[n]-1]:=valTemp[n,1]; // массив темпер-ры ХК
  SetLength(arrMK[n],NumVal[n]); arrMK[n,NumVal[n]-1]:=valTemp[n,2]; // массив темпер-ры ХК
end;

procedure DataInRecords(n:integer); // запись данных испытания в переменную Data
var st:string; i,j:integer;
begin
  Data[n].State:=StatePos[n];
  if prEditModel then
    st:=curKod
  else
    with fMain do with TJvEdit(FindComponent('edKod_' + IntToStr(n))) do st:=Text;
  if Length(st)<12 then
    for i:=1 to 12-Length(st) do st:=st+' ';
  Data[n].kodXP       :=st;
  Data[n].Tokr        := Tokr;
  Data[n].bgnTokr     := bgnTokr[n];
  for i:=1 to 7 do begin
    Data[n].endTokr[i]     := endTokr[n,i];
    Data[n].nChTemp[i]     := nChTemp[n,i];
    Data[n].flSavePar[i]   := flSavePar[n,i];
    Data[n].tpCheck[i]     := tpCheck[n,i];
    Data[n].flW[i]         := flW[n,i];
    Data[n].pmW[i]         := pmW[n,i];
    Data[n].ttW[i]         := ttW[n,i];
    Data[n].nChW[i]        := nChW[n,i];
    Data[n].flWch[i]       := flWch[n,i];
    Data[n].pmWch[i]       := pmWch[n,i];
    Data[n].ttWch[i]       := ttWch[n,i];
    Data[n].ttXK[i]        := ttXK[n,i];
    Data[n].pmXK[i]        := pmXK[n,i];
    Data[n].ttMK[i]        := ttMK[n,i];
    Data[n].pmMK[i]        := pmMK[n,i];
    Data[n].flBlockXK[i]   := flBlockXK[n,i];
    Data[n].flBlockMK[i]   := flBlockMK[n,i];
    Data[n].TempBlockXK[i] := TempBlockXK[n,i];
    Data[n].TempBlockMK[i] := TempBlockMK[n,i];
    Data[n].ttBlockXK[i]   := ttBlockXK[n,i];
    Data[n].ttBlockMK[i]   := ttBlockMK[n,i];
    Data[n].resBlockXK[i]  := resBlockXK[n,i];
    Data[n].resBlockMK[i]  := resBlockMK[n,i];
    for j:=1 to 2 do begin
      Data[n].pmRangeXK[i,j]   := pmRangeXK[n,i,j];  // (1-max,2-min)
      Data[n].pmRangeMK[i,j]   := pmRangeMK[n,i,j];  // (1-max,2-min)
    end;
  end;
  Data[n].tmStart     :=tmStart[n];
  Data[n].TimeAllIsp  :=TimeAllIsp[n];
  Data[n].TimeOffCmp  := TimeOffCmp[n];
  Data[n].flOnCmp     := flOnCmp[n];
  Data[n].numOnCmp    := numOnCmp[n];
  Data[n].numOffCmp   := numOffCmp[n];
  Data[n].wCmp        := wCmp[n];
  Data[n].ttCmp       := ttCmp[n];
  Data[n].TmrPerW2    := TmrPerW[n,2];
  Data[n].nCheckPoint := nCheckPoint[n];
  Data[n].nPointBlock := nPointBlock[n];
  Data[n].tmOnWork1   := tmOnWork1[n];
  Data[n].flWork1     := flWork1[n];
  Data[n].flActive    := flActive[n];
  Data[n].flPassive   := flPassive[n];
  Data[n].flWork2     := flWork2[n];
  Data[n].flSumm      := flSumm[n];
  Data[n].ttWH        := ttWH[n];
  Data[n].bgnWch      := bgnWch[n];
  Data[n].curWch      := curWch[n];
  Data[n].flToffXK    := flToffXK[n];
  Data[n].flToffMK    := flToffMK[n];
  Data[n].ttToffXK    := ttToffXK[n];
  Data[n].ttToffMK    := ttToffMK[n];
  Data[n].flTonXK     := flTonXK[n];
  Data[n].flTonMK     := flTonMK[n];
  Data[n].ttTonXK     := ttTonXK[n];
  Data[n].ttTonMK     := ttTonMK[n];
  st:=KodBrak[n];
  if Length(st)<10 then
    for i:=1 to 10-Length(st) do st:=st+' ';
  Data[n].KodBrak   := st;
  Data[n].NumVal:=NumVal[n];
  Data[n].Txk[NumVal[n]-1]:=valTemp[n,1];
  Data[n].Tmk[NumVal[n]-1]:=valTemp[n,2];
  Data[n].W[NumVal[n]-1]:=valW[n];
end;

procedure WriteDataInFile(n:integer); // запись данных в файл
var st:string; i:integer;
begin
  DataInRecords(n);
    //
  AssignFile(fData,MyDir+'DataIsp\data_'+IntToStr(n)+'.dat'); rewrite(fData);
  write(fData,Data[n]); CloseFile(fData);
end;

procedure DataIspPos(n:integer); // данные испытания на экран из файла
var i,j,k,nP:integer; st,sth,kod:string; tm:TDateTime; hh,mm,ss,ms:word; ft:textfile;
begin
  with fMain do begin
    Tokr:=Data[n].Tokr;
    bgnTokr[n]:=Data[n].bgnTokr;
    for i:=1 to 7 do endTokr[n,i]:=Data[n].endTokr[i];
    nCheckPoint[n]:=Data[n].nCheckPoint;
    nPointBlock[n]:=Data[n].nPointBlock;
    curPointXK[n]:=nPointBlock[n];
    if nPointBlock[n]=0 then nPointBlock[n]:=1;
      //
    st:=Data[n].kodXP;
//    if st<>'' then
      while st[Length(st)]=' ' do begin
        delete(st,Length(st),1);
        if st='' then break;
      end;
    if Length(st)>=3 then begin
      kod:=st; st:=copy(st,1,3);
      if dm.spXP.Locate('kod',st,[loCaseInsensitive]) then begin
      ParamsXP(n,true);
      if flParams[n] then begin      
        nP:=dm.spXP.RecNo; dm.spXP.RecNo:=nP;
        with TLabel(FindComponent('lModel_' + IntToStr(n))) do begin Caption:=dm.spXP['Model']; Enabled:=true; end;
        with TJvEdit(FindComponent('edKod_' + IntToStr(n))) do Text:=kod;
          //
        StatePos[n]:=Data[n].State;
        tmStart[n]:=Data[n].tmStart;
        TimeAllIsp[n]:=Data[n].TimeAllIsp;
          // время испытания
        if StatePos[n]=1 then tm:=Now-tmStart[n] else tm:=TimeAllIsp[n];
        DecodeTime(tm,hh,mm,ss,ms); mmCur[n]:=60*hh+mm;
        if TimeIsp[n]>200 then begin
          hh:=trunc(mmCur[n]/60); mm:=mmCur[n] - hh*60; sth:=IntToStr(hh);
          if Length(sth)=1 then sth:='0'+sth; st:=sth+':'; sth:=IntToStr(mm);
          if Length(sth)=1 then sth:='0'+sth; st:=st+sth;
        end else st:=IntToStr(mmCur[n]);
        with TPanel(FindComponent('pCurTime_'+IntToStr(n))) do Caption:=st;
          //
        flOnCmp[n]:=Data[n].flOnCmp;
        TimeOffCmp[n]:=Data[n].TimeOffCmp; // время 1-го отключения компрессора
        numOnCmp[n]:=Data[n].numOnCmp;
        numOffCmp[n]:=Data[n].numOffCmp;
        with TPanel(FindComponent('pCycl_'+IntToStr(n))) do Caption:=IntToStr(numOffCmp[n]);
          //
        wCmp[n]:=Data[n].wCmp;
        ttCmp[n]:=Data[n].ttCmp;
        if wCmp[n] then begin
          if not ttCmp[n] then
            with TImage(FindComponent('ImgNoOff_'+IntToStr(n))) do Visible:=false;
        end;
          // Full No Frost
        tmOnWork1[n]:=Data[n].tmOnWork1;
        flWork1[n]:=Data[n].flWork1;
        flActive[n]:=Data[n].flActive;
        flPassive[n]:=Data[n].flPassive;
        flWork2[n]:=Data[n].flWork2;
        if flActive[n] then with TJvLED(FindComponent('LedA_'+IntToStr(n))) do ColorOn:=clLime
        else if flWork2[n] then with TJvLED(FindComponent('LedA_'+IntToStr(n))) do ColorOn:=clRed;
        if flPassive[n] then with TJvLED(FindComponent('LedP_'+IntToStr(n))) do ColorOn:=clLime
        else if flWork2[n] then with TJvLED(FindComponent('LedP_'+IntToStr(n))) do ColorOn:=clRed;
          //
        curWch[n]:=Data[n].curWch;
        bgnWch[n]:=Data[n].bgnWch;
        flToffXK[n]:=Data[n].flToffXK;
        flToffMK[n]:=Data[n].flToffMK;
        ttToffXK[n]:=Data[n].ttToffXK;
        ttToffMK[n]:=Data[n].ttToffMK;
        flTonXK[n]:=Data[n].flTonXK;
        flTonMK[n]:=Data[n].flTonMK;
        ttTonXK[n]:=Data[n].ttTonXK;
        ttTonMK[n]:=Data[n].ttTonMK;
          //
        for i:=1 to 7 do begin
          flW[n,i]:=Data[n].flW[i];
          pmW[n,i]:=Data[n].pmW[i];
          ttW[n,i]:=Data[n].ttW[i];
          nChW[n,i]:=Data[n].nChW[i];
            //
          flWch[n,i]:=Data[n].flWch[i];
          ttWch[n,i]:=Data[n].ttWch[i];
          pmWch[n,i]:=Data[n].pmWch[i];
            //
          ttXK[n,i]:=Data[n].ttXK[i];
          pmXK[n,i]:=Data[n].pmXK[i];
          ttMK[n,i]:=Data[n].ttMK[i];
          pmMK[n,i]:=Data[n].pmMK[i];
            //
          nChTemp[n,i]:=Data[n].nChTemp[i];
          flSavePar[n,i]:=Data[n].flSavePar[i];
          tpCheck[n,i]:=Data[n].tpCheck[i];
            //
          flBlockXK[n,i]:=Data[n].flBlockXK[i];
          flBlockMK[n,i]:=Data[n].flBlockMK[i];
          ttBlockXK[n,i]:=Data[n].ttBlockXK[i];
          ttBlockMK[n,i]:=Data[n].ttBlockMK[i];
          TempBlockXK[n,i]:=Data[n].TempBlockXK[i];
          TempBlockMK[n,i]:=Data[n].TempBlockMK[i];
          resBlockXK[n,i]:=Data[n].resBlockXK[i];
          resBlockMK[n,i]:=Data[n].resBlockMK[i];
          for j:=1 to 2 do begin
            pmRangeXK[n,i,j]:=Data[n].pmRangeXK[i,j];
            pmRangeMK[n,i,j]:=Data[n].pmRangeMK[i,j];
          end;
        end;
          //
        NumVal[n]:=Data[n].NumVal;                                       
        SetLength(arrW[n],NumVal[n]); SetLength(arrXK[n],NumVal[n]); SetLength(arrMK[n],NumVal[n]);
          // сохранить мощность
        AssignFile(ft,'arrW.dat'); rewrite(ft);
        for j:=0 to NumVal[n]-1 do begin
          arrW[n,j]:=Data[n].W[j];  writeln(ft, realToStr(Data[n].W[j],5,1));
          arrXK[n,j]:=Data[n].Txk[j];
          arrMK[n,j]:=Data[n].Tmk[j];
        end;
        CloseFile(ft);
          //
        valW[n]:=Data[n].W[NumVal[n]-1];
        valTemp[n,1]:=Data[n].Txk[NumVal[n]-1];
        valTemp[n,2]:=Data[n].Tmk[NumVal[n]-1];
          //
        TmrPerW[n,2]:=Data[n].TmrPerW2;
          // расход эл/эн ХП
        if flWch[n,nPointBlock[n]] then k:=nPointBlock[n]
        else begin
          for i:=nPointBlock[n] downto 1 do
            if flWch[n,i] then begin k:=i; break; end;
        end;
        with TPanel(FindComponent('pCurWch_'+IntToStr(n))) do Caption:=RealToStr(curWch[n],5,0);
          // блоки при переходе через контр.точки и после окончания испытания
        if ((chBlockMK[n])or(chBlockXK[n])) then begin
          if chBlockXK[n] then begin
            if (flBlockXK[n,nPointBlock[n]])and((tpCheck[n,nPointBlock[n]])or((not tpCheck[n,nPointBlock[n]])and(StatePos[n]>1))) then
              with TJvEdit(FindComponent('EdBlockXK_'+IntToStr(n))) do begin
                Text:=RealToStr(ttBlockXK[n,nPointBlock[n]],5,1); Enabled:=true;
                if (pmDopBlXK[n]<>0)and(Abs(ttBlockXK[n,nPointBlock[n]]-TempBlockXK[n,nPointBlock[n]])>pmDopBlXK[n])
                  then Color:=$00947DEC else Color:=$00ACF471;
              end;
            if (not flBlockXK[n,nPointBlock[n]])and(StatePos[n]=1)and(colPoint[n]>1)and(nPointBlock[n]<nCheckPoint[n]) then begin
              with TJvEdit(FindComponent('EdBlockXK_'+IntToStr(n))) do begin
                Text:=''; Color:=clYellow; Enabled:=true; ReadOnly:=false;
              end;
              limitBlockXK(n,nPointBlock[n]);
              with TLabel(FindComponent('ltBlock_'+IntToStr(n))) do Caption:=chPointToScreen(n,nPointBlock[n],'Показания на ');
            end;
          end;
            //
          if chBlockMK[n] then begin
            if (flBlockMK[n,nPointBlock[n]]) then
              if (flBlockMK[n,nPointBlock[n]])and((tpCheck[n,nPointBlock[n]])or((tpCheck[n,nPointBlock[n]])and(StatePos[n]>1))) then
                with TJvEdit(FindComponent('EdBlockMK_'+IntToStr(n))) do begin
                  Text:=RealToStr(ttBlockMK[n,nPointBlock[n]],5,1); Enabled:=true;
                  if (pmDopBlMK[n]<>0)and(Abs(ttBlockMK[n,nPointBlock[n]]-TempBlockMK[n,nPointBlock[n]])>pmDopBlMK[n])
                    then Color:=$00947DEC else Color:=$00ACF471;
                end;
            if (not flBlockMK[n,nPointBlock[n]])and(StatePos[n]=1)and(colPoint[n]>1)and(nPointBlock[n]<nCheckPoint[n]) then begin
              with TJvEdit(FindComponent('EdBlockMK_'+IntToStr(n))) do begin
                Text:=''; Color:=clYellow; Enabled:=true; ReadOnly:=false;
              end;
              limitBlockMK(n,nPointBlock[n]);
              with TLabel(FindComponent('ltBlock_'+IntToStr(n))) do Caption:=chPointToScreen(n,nPointBlock[n],'Показания на ');
            end;
          end;
        end;
          //
        flSumm[n]:=Data[n].flSumm;
        ttWH[n]:=Data[n].ttWH;
        if flSumm[n] then begin
          with TImage(FindComponent('ImgH_'+IntToStr(n))) do Visible:=false;
          with TPanel(FindComponent('pCurWH_'+IntToStr(n))) do begin
            Caption:=RealToStr(ttWH[n],5,0);
            if(Round(ttWH[n])>=pmWHmin[n])and(Round(ttWH[n])<=pmWHmax[n]) then Color:=$00ACF471 else Color:=$00947DEC;
          end;
        end;
          //
        if StatePos[n]=2 then begin
          numOff[n]:=0;
          with TJvXPButton(FindComponent('BtnState_' + IntToStr(n))) do Glyph.LoadFromFile(MyDir+'Img\Blue.bmp');
            // компрессор
          if (chOffCmp[n])and(numOffCmp[n]=0) then
            with TImage(FindComponent('ImgNoOff_'+IntToStr(n))) do Visible:=true;
          if (chBlockMK[n])and(not flBlockMK[n,nPointBlock[n]]) then
            with TJvEdit(FindComponent('EdBlockMK_'+IntToStr(n))) do begin
              Text:=''; Color:=clYellow; Enabled:=true; ReadOnly:=false;
            end;
          if (chBlockXK[n])and(not flBlockXK[n,nPointBlock[n]]) then begin
            with TJvEdit(FindComponent('EdBlockXK_'+IntToStr(n))) do begin
              Text:=''; Color:=clYellow; Enabled:=true; ReadOnly:=false;
            end;
            if colPoint[n]>1 then begin
              limitBlockXK(n,nPointBlock[n]);
              with TLabel(FindComponent('ltBlock_'+IntToStr(n))) do Caption:=chPointToScreen(n,nPointBlock[n],'Показания на ');
            end;
          end;
          if (chToffMK[n])and(not flToffMK[n]) then
            with TJvEdit(FindComponent('EdToffMK_'+IntToStr(n))) do begin
              Text:=''; Color:=clYellow; Enabled:=true; ReadOnly:=false;
            end;
          if (chToffXK[n])and(not flToffXK[n]) then
            with TJvEdit(FindComponent('EdToffXK_'+IntToStr(n))) do begin
              Text:=''; Color:=clYellow; Enabled:=true; ReadOnly:=false;
            end;
          if (chTonMK[n])and(not flTonMK[n]) then
            with TJvEdit(FindComponent('EdTonMK_'+IntToStr(n))) do begin
              Text:=''; Color:=clYellow; Enabled:=true; ReadOnly:=false;
            end;
          if (chTonXK[n])and(not flTonXK[n]) then
            with TJvEdit(FindComponent('EdTonXK_'+IntToStr(n))) do begin
              Text:=''; Color:=clYellow; Enabled:=true; ReadOnly:=false;
            end;
        end;
          //
        if (numOffCmp[n]>0)and{(chMetod[n]='End')and}(flW[n,nPointBlock[n]]) then CheckParamWatt(n,nPointBlock[n]); // оценка мощности ХП
        if flSavePar[n,nPointBlock[n]] then begin
          ParamIspInScreen(n,nPointBlock[n]);
            // расход эл/эн ХП
{          if flWch[n,nPointBlock[n]] then k:=nPointBlock[n]
          else begin
            for i:=nPointBlock[n] downto 1 do
              if flWch[n,i] then begin k:=i; break; end;
          end;  }
          if flWch[n,k] then CheckParamWch(n,k);
        end;
          //
        KodBrak[n]:=Data[n].KodBrak;
          //
        if (StatePos[n]>1)or((StatePos[n]=1)and(nPointBlock[n]<nCheckPoint[n])) then begin
          if (chBlockMK[n])or(chBlockXK[n]) then
            with TJvScrollBox(FindComponent('scbBlock'+IntToStr(n))) do begin VertScrollBar.Position:=0; Enabled:=true; end;
        end;
        with TJvXPButton(FindComponent('BtnState_' + IntToStr(n))) do begin
          Enabled:=true;
          if StatePos[n]<2 then
            if (arrW[n,NumVal[n]-1]>UstW)and(arrW[n,NumVal[n]-2]>UstW)
              then Glyph.LoadFromFile(MyDir+'Img\Green.bmp')
              else Glyph.LoadFromFile(MyDir+'Img\Yellow.bmp');
        end;
          //
        if (bgChTm[n])or((not bgChTm[n])and(mmCur[n]>=TimeIsp[n]-CheckTime[n,nPointBlock[n]])) then begin
          if bgnTokr[n]=0 then bgnTokr[n]:=Tokr;
          with TLabel(FindComponent('lChTm_'+IntToStr(n))) do Visible:=true;
        end;
        if (((bgChTm[n])and(mmCur[n]>=CheckTime[n,nPointBlock[n]]))or
           ((not bgChTm[n])and(mmCur[i]>=TimeIsp[n]))) then begin
          with TLabel(FindComponent('lChTm_'+IntToStr(n))) do Visible:=false;
        end;
          //
        if StatePos[n]=3 then begin
          ResultIsp(n,nPointBlock[n],false);  // оценка результата испытания
          if ResIsp[n]
            then with TJvXPButton(FindComponent('BtnState_' + IntToStr(n))) do Glyph.LoadFromFile(MyDir+'Img\Ok.bmp')
            else with TJvXPButton(FindComponent('BtnState_' + IntToStr(n))) do Glyph.LoadFromFile(MyDir+'Img\brak.bmp');
          if ((chBlockMK[n])or(chBlockXK[n]))and(nCheckPoint[n]>1) then begin
            if chBlockXK[n] then begin
             curPointXK[n]:=nPointBlock[n];
              with TUpDown(FindComponent('UpDwnXK'+IntToStr(n))) do Enabled:=true;
            end;
            if chBlockMK[n] then begin
              curPointMK[n]:=nPointBlock[n];
              with TUpDown(FindComponent('UpDwnMK'+IntToStr(n))) do Enabled:=true;
            end;
            with TLabel(FindComponent('ltBlock_'+IntToStr(n))) do Caption:=chPointToScreen(n,curPointXK[n],'Показания на ');
          end;
            //
          if flToffXK[n] then
            with TJvEdit(FindComponent('EdToffXK_'+IntToStr(n))) do begin
              Text:=RealToStr(ttToffXK[n],5,1); Enabled:=true;
              if (chToffXK[n])and(Abs(ttToffXK[n]-pmToffXK[n])>0.3) then Color:=$00947DEC else Color:=$00ACF471;
            end;
          if flToffMK[n] then
            with TJvEdit(FindComponent('EdToffMK_'+IntToStr(n))) do begin
              Text:=RealToStr(ttToffMK[n],5,1); Enabled:=true;
              if (chToffMK[n])and(Abs(ttToffMK[n]-pmToffMK[n])>0.3) then Color:=$00947DEC else Color:=$00ACF471;
            end;
          if flTonXK[n] then
            with TJvEdit(FindComponent('EdTonXK_'+IntToStr(n))) do begin
              Text:=RealToStr(ttTonXK[n],5,1); Enabled:=true;
              if (chTonXK[n])and(Abs(ttTonXK[n]-pmTonXK[n])>0.3) then Color:=$00947DEC else Color:=$00ACF471;
            end;
          if flTonMK[n] then
            with TJvEdit(FindComponent('EdTonMK_'+IntToStr(n))) do begin
              Text:=RealToStr(ttTonMK[n],5,1); Enabled:=true;
              if (chTonMK[n])and(Abs(ttTonMK[n]-pmTonMK[n])>0.3) then Color:=$00947DEC else Color:=$00ACF471;
            end;
        end;
          //
{        with TJvXPButton(FindComponent('BtnState_' + IntToStr(n))) do begin
          Enabled:=true;
          if StatePos[n]<2 then
            if (arrW[n,NumVal[n]-1]>UstW[n])and(arrW[n,NumVal[n]-2]>UstW[n])
              then Glyph.LoadFromFile(MyDir+'Img\Green.bmp')
              else Glyph.LoadFromFile(MyDir+'Img\Yellow.bmp');
        end;
          //
        if (bgChTm[n]) or ((not bgChTm[n])and(mmCur[n]>=TimeIsp[n]-CheckTimeIsp[n])) then begin
          if ispTokr[n,1]=0 then ispTokr[n,1]:=Tokr;
          with TLabel(FindComponent('lChTm_'+IntToStr(n))) do Visible:=true;
        end;
        if (((bgChTm[n])and(mmCur[n]>=CheckTimeIsp[n]))or
           ((not bgChTm[n])and(mmCur[i]>=TimeIsp[n]))) then begin
          with TLabel(FindComponent('lChTm_'+IntToStr(n))) do Visible:=false;
        end; }

      end;
    end;
    end;
  end;
end;

procedure proverkaDef;
begin stLog:=''; otv:=true;
 if (DM.spDefKod.OldValue<>DM.spDefKod.NewValue) then begin
   DM.spDef2.Filter:='[Kod]='+DM.spDef.FieldByName('Kod').AsString;
   DM.spDef2.Filtered:=true;
   if Dm.spDef2.RecordCount>0 then
     begin
       MessageDlgPos('Введенный код есть в БД!!! Сохранение невозможно!',mtWarning,[mbOk],0,{x}fMain.Left+250,{y}fMain.Top+350);
       otv:=false;
     end
     else stLog:='кода c "'+intToStr(dm.spDefKod.OldValue)+'" на "'+intToStr(dm.spDefKod.NewValue)+'" ';
   dm.spDef2.Filtered:=false;
 end;

 Id:=DM.spDef['idDef'];//дефект не повторяется-отслеживается в БД!!! и срабатывает DefPostError в UDM
 if (dm.spDefDef.NewValue<>dm.spDefDef.OldValue)and (otv) then
  begin proverka(DM.spDef['Def']);
    if otv=false then  DM.spDef['Def']:='';
    if otv then
        begin  (*DM.spDef2.Filter:='[Def]='+DM.spDef.FieldByName('Def').AsString;
          DM.spDef2.Filtered:=true;
          if Dm.spDef2.RecordCount>0*)
          if DM.spDef2.Locate('Def',DM.spDef.FieldByName('Def').AsString,[LoCaseInsensitive])
            then begin
              MessageDlgPos('Введенный дефект есть в БД!!! Сохранение невозможно!',mtWarning,[mbOk],0,{x}fMain.Left+250,{y}fMain.Top+350);
              otv:=false;
            end
            else stLog:=stLog+'дефекта c "'+dm.spDefDef.OldValue+'" на "'+dm.spDefDef.NewValue+'"';
          dm.spDef2.Filtered:=false;
        end;
  end;
 if (DM.spDef['Def']='')or(DM.spDef['Kod']=null)then
    begin
      MessageDlgPos('<Редактирование> - предполагает исправление орфографических ошибок!!!',mtWarning,[mbOk],0,{x}fMain.Left+250,{y}fMain.Top+350);
      otv:=false;
    end;
end;

procedure proverka(st:string); {проверка строки из пробелов}
var i,j:integer;
 begin j:=0;
 for i:=1 to length(st) do
  begin if st[i]=' ' then j:=j+1;  end;
   if (j=length(st)) then otv:=false else otv:=true;
end;

function definePoint(n:integer):integer;  // определить на какой контр. точке для оценки рез-та
begin
  if nPointBlock[n]=nCheckPoint[n] then Result:=nCheckPoint[n]
  else
    if tpCheck[n,nPointBlock[n]] then Result:=nCheckPoint[n]
    else Result:=nPointBlock[n];
end;

procedure ReturnPrevCode; // возврат предыдущего кода ХР при неудачном редактировании кода
begin
  dm.spXP.Close; dm.spXP.Open;
  if dm.spXP.Locate('kod',curKod,[loCaseInsensitive]) then
  begin
    ParamsXP(nPos,false);
    if flParams[nPos] then
    begin
      with fMain do with TJvEdit(FindComponent('edKod_'+IntToStr(nPos))) do
      begin
        Color:=clWindow; ReadOnly:=true; Text:=curKod; {Data[nPos].kodXP:=Text;}
      end;
      if prEditModel then {DataIspPos(curPos)};
      prEditModel:=false;
    end;
  end;
end;

procedure limitBlockXK(n,nPoint:integer); // вывод на экран параметров оценки блоков XK
var st1,st2:string;
begin
  with fMain do begin
    if not flRangeXK[n,nPoint] then begin
      with TLabel(FindComponent('lmBlockXK_'+IntToStr(n))) do
        begin Visible:=true; Caption:='Tхк '+#177+' '+IntToStr(pmDopBlXK[n]); end;
    end;
    if flRangeXK[n,nPoint] then begin
      with TLabel(FindComponent('lmBlockXK_'+IntToStr(n))) do begin
        Visible:=true; st1:=''; st2:='';
        if pmRangeXK[n,nPoint,1] > 0 then st1:='+';
        if pmRangeXK[n,nPoint,2] > 0 then st2:='+';
        Caption:=st2+RealToStr(pmRangeXK[n,nPoint,2],3,1)+' '+st1+RealToStr(pmRangeXK[n,nPoint,1],3,1);
      end;
    end;
  end;
end;

procedure limitBlockMK(n,nPoint:integer); // вывод на экран параметров оценки блоков MK
var st1,st2:string;
begin
  with fMain do begin
    if not flRangeMK[n,nPoint] then begin
      with TLabel(FindComponent('lmBlockMK_'+IntToStr(n))) do
        begin Visible:=true; Caption:='Tмк '+#177+' '+IntToStr(pmDopBlMK[n]); end;
    end;
    if flRangeMK[n,nPoint] then begin
      with TLabel(FindComponent('lmBlockMK_'+IntToStr(n))) do begin
        Visible:=true; st1:=''; st2:='';
        if pmRangeMK[n,nPoint,1] > 0 then st1:='+';
        if pmRangeMK[n,nPoint,2] > 0 then st2:='+';
        Caption:=st2+RealToStr(pmRangeMK[n,nPoint,2],3,1)+' '+st1+RealToStr(pmRangeMK[n,nPoint,1],3,1);
      end;
    end;
  end;
end;

function chPointToScreen(n,nPoint:integer; startStr:string):string; // вывод на экран ожидаемой контрольной точки
var ch,st,str:string;
begin
  if colPoint[n]>1 then begin
    if CheckTime[n,nPoint]<=200
      then st:=startStr+IntToStr(CheckTime[n,nPoint])+' мин.'
      else st:=startStr+IntToStr(trunc(CheckTime[n,nPoint]/60))+' ч.';
  end
  else st:='Показания';
  Result:=st;
end;

procedure ResultChPoinTempWtWtch(n,colPoint:integer; tpCh:boolean); // оценка Tхк,Тмк,Wt,Wtch на контрольной точке
var flRes:boolean; i:integer; st:string;
begin
  flRes:=true; KodBrak[n]:='';
    // оценка температуры в ХК и МК
  if ((TypeXP[n]='хм')or(TypeXP[n]='хк')or(TypeXP[n]='мм')or(TypeXP[n]='хх'))and(not ResTemptAllPoint(n,colPoint,ttXK,pmXK,tpCh)) then flRes:=false;
  if ((TypeXP[n]='хм')or(TypeXP[n]='мк')or(TypeXP[n]='мм')or(TypeXP[n]='хх'))and(not ResTemptAllPoint(n,colPoint,ttMK,pmMK,tpCh)) then flRes:=false;
  if (flW[n,colPoint])and(not ResTemptAllPoint(n,colPoint,ttW,pmW,tpCh)) then flRes:=false;// завышена мощность ХП
  if (flWch[n,colPoint])and(not ResTemptAllPoint(n,colPoint,ttWch,pmWch,tpCh)) then flRes:=false; // завышен расход эл/эн.
  ResIsp[n]:=flRes;
end;

procedure InitializeTestVars (i:integer);
begin
  StatePos[i]:=1;

  flOnCmp[i]:=true;
  Inc(numOnCmp[i]);

   // необходимо, если будет FNF
  flWork1[i]:=true; tmOnWork1[nPos]:=tmStart[i];
  RecordStartValueCheckPoint(i);

end;


procedure InitializeTestInterface(i: integer);
begin
  if not flParams[i] then
    with fMain do
    begin
          //доступность ввода кода пользователем
      with TJvEdit(FindComponent('edKod_' + IntToStr(i))) do
      begin
        Enabled := true;
        Color := clYellow;
      end;

      with TLabel(FindComponent('lModel_' + IntToStr(i))) do
        Enabled := true;
      with TJvXPButton(FindComponent('BtnState_' + IntToStr(i))) do
      begin
        Enabled := true;
        Glyph.LoadFromFile(MyDir + 'Img\Green.bmp');
      end;
      with TPanel(FindComponent('pCycl_' + IntToStr(i))) do
        Caption := '0';
    end;
end;


procedure HandleSelectedModel (i:integer);
begin
  CheckCompressorOnState(i);
  CheckCompressorOffState (i);

end;




procedure HandleFirstCompressorOff (i:integer);
              begin
                wCmp[i]:=true;
                ttCmp[i]:=true;
                TimeOffCmp[i]:=Now-tmStart[i];
                //**************** Состояние 1 ****************  первое отключение компрессора *****метод энд*****
                if chMetod[i]='End' then
                begin // сохраняем только мощность ХП
                  if flW[i,nCheckPoint[i]] then
                  begin
                    ttW[i,nCheckPoint[i]]:=arrW[i,NumVal[i]-3]; nChW[i,nCheckPoint[i]]:=NumVal[i]-3;
                    CheckParamWatt(i,nCheckPoint[i]); // оценка мощности ХП
                  end;
                end
                //**************** Состояние 1 ****************  первое отключение компрессора *****метод НЕ энд*****
                else // сохраняем все параметры
                if endTokr[i,nCheckPoint[i]]=0 then
                begin // если параметры еще не сохранялись
                  endTokr[i,nCheckPoint[i]]:=Tokr;
                  SaveParamIsp(i); // при первом отключении сохраняем результаты
                  ParamIspInScreen(i,nCheckPoint[i]); // вывод параметров испытаний на экран
                end;
              end;

procedure CheckCompressorOnState (i:integer);
begin

end;

procedure CheckCompressorOffState (i:integer);
        begin
            // проверка отключения компрессора
          if (numOnCmp[i]>numOffCmp[i])and
             ((chMetod[i]<>'FnF')or((chMetod[i]='FnF')and(flWork2[i])))and
             ((arrW[i,NumVal[i]-3]-arrW[i,NumVal[i]-1])>UstW)
          then
          begin
               // дополнительная проверка отключения - не учитывать скачок напряжения
            if (arrW[i,NumVal[i]-1]<UstW)and(arrW[i,NumVal[i]-2]<UstW) then
            begin
              Inc(numOffCmp[i]);
              with TPanel(FindComponent('pCycl_'+IntToStr(i))) do Caption:=IntToStr(numOffCmp[i]);
              with TJvXPButton(FindComponent('BtnState_' + IntToStr(i))) do Glyph.LoadFromFile(MyDir+'Img\Yellow.bmp');

               //**************** Состояние 1 ****************  первое отключение компрессора ***********
              if numOffCmp[i]=1 then  HandleFirstCompressorOff(i);

            end;
          end;
        end;

procedure TimeDisplay (i:integer);

 hh,mm,ss,ms:Word;

  st,sth:string;
  tm:TDateTime;
begin
        //-- время испытания --
        tm:=Now-tmStart[i]; DecodeTime(tm,hh,mm,ss,ms); mmCur[i]:=60*hh+mm;
        if TimeIsp[i]>200 then
        begin
          hh:=trunc(mmCur[i]/60); mm:=mmCur[i] - hh*60; sth:=IntToStr(hh);
          if Length(sth)=1 then sth:='0'+sth; st:=sth+':'; sth:=IntToStr(mm);
          if Length(sth)=1 then sth:='0'+sth; st:=st+sth;
        end
        else st:=IntToStr(mmCur[i]);
        with TPanel(FindComponent('pCurTime_'+IntToStr(i))) do Caption:=st;
end;

procedure HandleUnSelectedModel (i:integer);
begin
  with fMain do
        begin
          // проверка включения компрессора
          if (numOnCmp[i]=numOffCmp[i])and((arrW[i,NumVal[i]-1]-arrW[i,NumVal[i]-2])>UstW) then
          begin
            Inc(numOnCmp[i]); // кол-во включений компрессора
            with TJvXPButton(FindComponent('BtnState_' + IntToStr(i))) do Glyph.LoadFromFile(MyDir+'Img\Green.bmp');
          end;
            // проверка отключения компрессора
          if (numOnCmp[i]>numOffCmp[i])and(arrW[i,NumVal[i]-1]<UstW)and(arrW[i,NumVal[i]-2]<UstW) then
          begin
            Inc(numOffCmp[i]);
            with TPanel(FindComponent('pCycl_'+IntToStr(i))) do Caption:=IntToStr(numOffCmp[i]);
//             with TJvXPButton(FindComponent('JvXPButton' + IntToStr(1))) do Glyph.LoadFromFile(MyDir+'Img\Yellow.bmp');
            with TJvXPButton(FindComponent('BtnState_' + IntToStr(i))) do Glyph.LoadFromFile(MyDir+'Img\Yellow.bmp');
          end;
          continue;
        end;
end;

procedure RecordStartValueCheckPoint (i:integer);
begin
 bgnTokr[i]:=Tokr;

 bgnWch[i]:=curWch[i];
 curWch[i]:=0;//??????


           // для расхода э/эн
        TmrPerW[i,1]:=Now;
         TmrPerW[i,2]:=TmrPerW[i,1];
end;

end.
