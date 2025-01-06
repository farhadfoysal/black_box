class DatabaseTable {

  static const ROOMS = '''
    CREATE TABLE IF NOT EXISTS Rooms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userid TEXT,
      campus_id TEXT,
      room_name TEXT,
      instructor_id TEXT,
      room_code TEXT,
      sId TEXT,
      status INTEGER,
      theory_lab INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const CAMPUS = '''
    CREATE TABLE IF NOT EXISTS Campus (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uniqueId TEXT,
      userid TEXT,
      campus_name TEXT,
      campus_code TEXT,
      sId TEXT,
      status INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const ADMIN = '''
    CREATE TABLE IF NOT EXISTS Admin (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uniqueId TEXT,
      aname TEXT,
      email TEXT,
      phone TEXT,
      sId TEXT,
      status INTEGER,
      utype INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const USER = '''
    CREATE TABLE IF NOT EXISTS User (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userid TEXT,
      uniqueId TEXT,
      uname TEXT,
      email TEXT,
      phone TEXT,
      pass TEXT,
      utype INTEGER,
      sId TEXT,
      status INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const UDATA = '''
    CREATE TABLE IF NOT EXISTS Udata (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      u_id TEXT,
      uniqueId TEXT,
      designation TEXT,
      fname TEXT,
      lname TEXT,
      phone TEXT,
      sId TEXT,
      photo BLOB,
      picture TEXT,
      fingerData BLOB,
      major TEXT,
      status INTEGER,
      address TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const USERS = '''
    CREATE TABLE IF NOT EXISTS Users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      u_id TEXT,
      uniqueId TEXT,
      currSessId TEXT,
      designation TEXT,
      name TEXT,
      email TEXT,
      phone TEXT,
      pass TEXT,
      bal TEXT,
      u_type INTEGER,
      sId TEXT,
      photo BLOB,
      picture TEXT,
      fingerData BLOB,
      stdId TEXT,
      major TEXT,
      status INTEGER,
      address TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const A_YEAR = '''
    CREATE TABLE IF NOT EXISTS aYear (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uId TEXT,
      aYname TEXT,
      uniqueId TEXT,
      sYear TEXT,
      sMonth TEXT,
      eYear TEXT,
      eMonth TEXT,
      aStatus INTEGER,
      sId TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const SECTIONS = '''
    CREATE TABLE IF NOT EXISTS sections (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sId TEXT,
      uniqueId TEXT,
      subId TEXT,
      sessionId TEXT,
      clsId TEXT,
      secName TEXT,
      secCode TEXT,
      secFee TEXT,
      secNumStd INTEGER,
      secTeaId TEXT,
      aStatus INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const SCHOOL = '''
    CREATE TABLE IF NOT EXISTS school (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sName TEXT,
      uniqueId TEXT,
      currSessId TEXT,
      sPhone TEXT,
      sPass TEXT,
      sEmail TEXT,
      sLogo TEXT,
      sId TEXT,
      sAdrs TEXT,
      sAYear TEXT,
      sEiin TEXT,
      sStudent INTEGER,
      sTeacher INTEGER,
      sCourse INTEGER,
      sSec INTEGER,
      sUser INTEGER,
      sClass INTEGER,
      sItp1 TEXT,
      sItp2 TEXT,
      sItEmail TEXT,
      sWeb TEXT,
      sFundsBal TEXT,
      sFundsBank TEXT,
      sFundsAN TEXT,
      sActivate INTEGER,
      sVerification TEXT,
      sEmpl INTEGER,
      proPic BLOB,
      sync_status INTEGER,
      sync_key TEXT,
      key TEXT
    );
  ''';

  static const MAJOR = '''
    CREATE TABLE IF NOT EXISTS Major (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sId TEXT,
      uniqueId TEXT,
      location TEXT,
      deanId TEXT,
      phone TEXT,
      mName TEXT,
      mStart TEXT,
      mEnd TEXT,
      mStatus INTEGER,
      currentId TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const STUDENTS = '''
    CREATE TABLE IF NOT EXISTS students (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sId TEXT,
      studentId TEXT,
      uniqueId TEXT,
      currSessId TEXT,
      stdId TEXT,
      uId TEXT,
      stdName TEXT,
      nidBirth TEXT,
      stdPhone TEXT,
      stdEmail TEXT,
      homePhone TEXT,
      stdReligion TEXT,
      dob TEXT,
      address TEXT,
      country TEXT,
      UnionWord TEXT,
      aStatus INTEGER,
      fatherName TEXT,
      motherName TEXT,
      fNid TEXT,
      mNid TEXT,
      gName TEXT,
      gAddress TEXT,
      gPhone TEXT,
      gEmail TEXT,
      stdImg TEXT,
      sMajor TEXT,
      stdPass TEXT,
      gender TEXT,
      addDate TEXT,
      proPic BLOB,
      lastlogin TEXT,
      sMajorId TEXT,
      sync_status INTEGER,
      program INTEGER,
      sync_key TEXT
    );
  ''';

  static const SUBJECT = '''
    CREATE TABLE IF NOT EXISTS subject (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subName TEXT,
      uniqueId TEXT,
      credit TEXT,
      subCode TEXT,
      subId TEXT,
      depId INTEGER,
      typeId INTEGER,
      subFee TEXT,
      status INTEGER,
      sId TEXT,
      semester TEXT,
      program INTEGER,
      departmentId TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const SUB_ON_SEC = '''
    CREATE TABLE IF NOT EXISTS subOnsec (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subAId TEXT,
      uniqueId TEXT,
      sId TEXT,
      subId INTEGER,
      subjectId TEXT,
      sectionId TEXT,
      secId INTEGER,
      aStatus INTEGER,
      subFee TEXT,
      secFee TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const SUB_ASSIGNED = '''
    CREATE TABLE IF NOT EXISTS subAssigned (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subId INTEGER,
      subjectId TEXT,
      uniqueId TEXT,
      secId INTEGER,
      sectionId TEXT,
      clsId INTEGER,
      classId TEXT,
      sId TEXT,
      stdId TEXT,
      feeTk TEXT,
      aStatus INTEGER,
      subAId TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const SEC_ASSIGNED = '''
    CREATE TABLE IF NOT EXISTS secAssigned (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      secId INTEGER,
      uniqueId TEXT,
      clsId INTEGER,
      stdId TEXT,
      sectionId TEXT,
      sessionId TEXT,
      classId TEXT,
      sId TEXT,
      date TEXT,
      aYear INTEGER,
      aStatus INTEGER,
      feeTk TEXT,
      secAId TEXT,
      aYearId INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const TEACHER = '''
    CREATE TABLE IF NOT EXISTS teacher (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sId TEXT,
      uniqueId TEXT,
      designation TEXT,
      tName TEXT,
      tPhone TEXT,
      tPass TEXT,
      tEmail TEXT,
      tAddress TEXT,
      aStatus INTEGER,
      tMajor TEXT,
      tBal TEXT,
      tLogo TEXT,
      tId TEXT,
      uType INTEGER,
      proPic BLOB,
      nidBirth TEXT,
      uId TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const ATTENDANCE_SHEET = '''
    CREATE TABLE IF NOT EXISTS attendanceSheet (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sId TEXT,
      uniqueId TEXT,
      stdId TEXT,
      subId INTEGER,
      subjectId TEXT,
      secId INTEGER,
      sectionId TEXT,
      teacherId TEXT,
      period TEXT,
      aStatus INTEGER,
      day TEXT,
      month TEXT,
      year TEXT,
      hour TEXT,
      minute TEXT,
      date TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const PAYMENT = '''
    CREATE TABLE IF NOT EXISTS payment (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      payId INTEGER,
      sId TEXT,
      uniqueId TEXT,
      payerId TEXT,
      paymentId TEXT,
      paymentSlip TEXT,
      trnx TEXT,
      type INTEGER,
      payMethod TEXT,
      stdId TEXT,
      stdName TEXT,
      payDate TEXT,
      pStatus INTEGER,
      sessionId TEXT,
      feeAmount TEXT,
      payAmount TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const FEE_TYPE = '''
    CREATE TABLE IF NOT EXISTS feeType (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fType TEXT,
      uniqueId TEXT,
      typeId TEXT,
      aStatus INTEGER,
      sId TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const MAIL = '''
    CREATE TABLE IF NOT EXISTS mail (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      mailId INTEGER,
      uniqueId TEXT,
      email TEXT,
      sId TEXT,
      fromName TEXT,
      mailTitle TEXT,
      mailContent TEXT,
      fromEmail TEXT,
      toName TEXT,
      dateTime TEXT,
      mailAttach TEXT,
      mailAttachFile BLOB,
      mailCode TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const FEE = '''
    CREATE TABLE IF NOT EXISTS fee (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sId TEXT,
      uniqueId TEXT,
      payId INTEGER,
      sessionId TEXT,
      secId INTEGER,
      sectionId TEXT,
      clsId INTEGER,
      classId TEXT,
      stdId TEXT,
      date TEXT,
      month TEXT,
      year TEXT,
      fee TEXT,
      subFee TEXT,
      aStatus INTEGER,
      subId INTEGER,
      subjectId TEXT,
      trnx TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const CLASSES = '''
    CREATE TABLE IF NOT EXISTS classes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sId TEXT,
      uniqueId TEXT,
      className TEXT,
      clsId INTEGER,
      status INTEGER,
      sMajor TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const ALL_SUBJECTS = '''
    CREATE TABLE IF NOT EXISTS allSubjects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sId TEXT,
      uniqueId TEXT,
      subject TEXT,
      aStatus INTEGER,
      clsId INTEGER,
      classId TEXT,
      depId INTEGER,
      departmentId TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const CLASS_SCHEDULE = '''
    CREATE TABLE IF NOT EXISTS classSchedule (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uniqueId TEXT,
      taskName TEXT,
      taskDetails TEXT,
      taskLocation TEXT,
      taskId INTEGER,
      taskCode TEXT,
      scheduleId INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const SCHEDULE = '''
  CREATE TABLE IF NOT EXISTS schedule (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uniqueId TEXT,
    sId TEXT,
    stdId TEXT,
    tId TEXT,
    temp_code TEXT,
    temp_num TEXT,
    sub_name TEXT,
    sub_code TEXT,
    t_id TEXT,
    t_name TEXT,
    room TEXT,
    campus TEXT,
    section TEXT,
    start_time TEXT,
    end_time TEXT,
    day TEXT,
    key TEXT,
    sync_key TEXT,
    min INTEGER,
    sync_status INTEGER,
    dateTime TEXT
  );
''';


  static const TASK = '''
    CREATE TABLE IF NOT EXISTS task (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uId TEXT,
      uniqueId TEXT,
      sId TEXT,
      aStatus INTEGER,
      taskName TEXT,
      taskDetails TEXT,
      taskLocation TEXT,
      taskId INTEGER,
      taskCode TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const NOTE = '''
    CREATE TABLE IF NOT EXISTS note (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      taskName TEXT,
      uniqueId TEXT,
      scheduleId INTEGER,
      sId TEXT,
      stdId TEXT,
      uId TEXT,
      userId TEXT,
      aStatus INTEGER,
      taskDetails TEXT,
      taskLocation TEXT,
      taskId INTEGER,
      taskCode TEXT,
      calendar TEXT,
      time TEXT,
      day TEXT,
      url TEXT,
      link TEXT,
      dateTime TEXT,
      done INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const CALENDAR = '''
    CREATE TABLE IF NOT EXISTS calendar (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uniqueId TEXT,
      scheduleId INTEGER,
      time TEXT,
      day TEXT,
      taskName TEXT,
      taskDetails TEXT,
      taskLocation TEXT,
      url TEXT,
      link TEXT,
      done INTEGER,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const ROUTINE = '''
    CREATE TABLE IF NOT EXISTS routine (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uniqueId TEXT,
      sId TEXT,
      time TEXT,
      day TEXT,
      subjectId TEXT,
      secId TEXT,
      sync_status INTEGER,
      sync_key TEXT
    );
  ''';

  static const TUTOR_STUDENT_TABLE = '''
  CREATE TABLE IF NOT EXISTS tutor_students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    user_id TEXT,
    name TEXT,
    phone TEXT,
    gaurdian_phone TEXT,
    phone_pass TEXT,
    dob TEXT,
    education TEXT,
    address TEXT,
    active_status INTEGER,
    admitted_date TEXT,
    img TEXT,
    days TEXT
  );
''';


  static const TUTOR_WEEK_DAY = '''
  CREATE TABLE IF NOT EXISTS tutor_week_days (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    student_id TEXT,
    user_id TEXT,
    day TEXT,
    time TEXT,
    minutes INTEGER,
    sync_status INTEGER,
    sync_key TEXT
  );
''';


  static const TUTOR_MONTH = '''
  CREATE TABLE IF NOT EXISTS tutor_month (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    student_id TEXT,
    user_id TEXT,
    month TEXT,
    start_date TEXT,
    end_date TEXT,
    paid_date TEXT,
    paid INTEGER DEFAULT 0,
    pay_tk TEXT,
    paid_tk TEXT,
    paid_by TEXT,
    sync_status INTEGER DEFAULT 0,
    sync_key TEXT
  );
''';


  static const TUTOR_DATE = '''
  CREATE TABLE IF NOT EXISTS tutor_date (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    month_id TEXT,
    user_id TEXT,
    day TEXT,
    date TEXT,
    day_date TEXT,
    attendance INTEGER DEFAULT 0,
    minutes INTEGER DEFAULT 0,
    sync_status INTEGER DEFAULT 0,
    sync_key TEXT
  );
''';

  static const MESS_USER_TABLE = '''
  CREATE TABLE IF NOT EXISTS mess_user (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    user_id TEXT,
    phone TEXT,
    email TEXT DEFAULT '',
    user_type TEXT DEFAULT 'u',
    phone_pass TEXT,
    mess_id TEXT DEFAULT '',
    active_status TEXT DEFAULT '0',
    bazar_start TEXT,
    bazar_end TEXT,
    qr TEXT DEFAULT '',
    img TEXT DEFAULT ''
  );
''';


  static const MESS_MAIN_TABLE = '''
  CREATE TABLE IF NOT EXISTS mess_main (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    m_id TEXT,
    mess_id TEXT,
    mess_name TEXT,
    mess_address TEXT,
    mess_pass TEXT,
    mess_admin_id TEXT,
    meal_update_status TEXT DEFAULT '1',
    admin_phone TEXT,
    start_date TEXT,
    sum_of_all_trx TEXT DEFAULT '0',
    u_perm TEXT DEFAULT '0',
    qr TEXT,
    currentMonth TEXT
  );
''';

  static const MY_MEALS_TABLE = '''
  CREATE TABLE IF NOT EXISTS my_meals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    mess_id TEXT,
    date TEXT,
    time TEXT,
    morning TEXT DEFAULT '0',
    launce TEXT DEFAULT '0',
    dinner TEXT DEFAULT '0',
    meal_update TEXT,
    sum_meal TEXT,
    meal_reset TEXT DEFAULT '0'
  );
''';

  static const BAZAR_LIST_TABLE = '''
  CREATE TABLE IF NOT EXISTS bazar_list (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    list_id TEXT,
    unique_id TEXT,
    mess_id TEXT,
    phone TEXT,
    list_details TEXT,
    amount TEXT,
    date_time TEXT,
    admin_notify TEXT DEFAULT '0'
  );
''';

  static const MESS_FEES_TABLE = '''
  CREATE TABLE IF NOT EXISTS mess_fees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mess_id TEXT,
    fee_type TEXT,
    amount TEXT,
    admin_id TEXT,
    date TEXT,
    status TEXT DEFAULT '1'
  );
''';

  static const OTHERS_FEE_TABLE = '''
  CREATE TABLE IF NOT EXISTS others_fee (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    mess_id TEXT,
    fee_type TEXT,
    amount TEXT DEFAULT '0',
    admin_id TEXT,
    date TEXT,
    status TEXT DEFAULT '1'
  );
''';

  static const PAYMENT_TABLE = '''
  CREATE TABLE IF NOT EXISTS payment (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    admin_id TEXT,
    mess_id TEXT,
    phone TEXT DEFAULT '',
    date_m TEXT,
    trx_id TEXT DEFAULT '',
    amount TEXT DEFAULT '0',
    clear_trx TEXT DEFAULT '1',
    print INTEGER DEFAULT 0,
    time TEXT
  );
''';

  static const ACCOUNT_PRINT_TABLE = '''
  CREATE TABLE IF NOT EXISTS account_print (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_id TEXT,
    user_name TEXT,
    phone TEXT,
    mess_month_ex TEXT,
    my_expense TEXT,
    meal_expense TEXT,
    my_month_meal TEXT,
    pay_or_recieve TEXT,
    trx_clear_id TEXT DEFAULT '0'
  );
''';



}