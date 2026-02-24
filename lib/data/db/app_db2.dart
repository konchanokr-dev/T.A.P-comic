import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tapcomic.db');

    return openDatabase(
      path,
      version: 11, 
      onConfigure: (db) async {
       
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createAllTables(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS comic_detail (
              comic_id INTEGER PRIMARY KEY,
              author TEXT NOT NULL,
              genres TEXT NOT NULL,
              synopsis TEXT NOT NULL,
              FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS episode (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              comic_id INTEGER NOT NULL,
              ep_no INTEGER NOT NULL,
              title TEXT NOT NULL,
              UNIQUE(comic_id, ep_no),
              FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE
            )
          ''');
        }

      
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS page (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              episode_id INTEGER NOT NULL,
              page_no INTEGER NOT NULL,
              image_path TEXT NOT NULL,
              UNIQUE(episode_id, page_no),
              FOREIGN KEY (episode_id) REFERENCES episode(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comic_id INTEGER NOT NULL,
        episode_id INTEGER NOT NULL,
        page_no INTEGER NOT NULL DEFAULT 0,
        last_read_at TEXT NOT NULL,
        UNIQUE(comic_id, episode_id),
        FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE,
        FOREIGN KEY (episode_id) REFERENCES episode(id) ON DELETE CASCADE
      )
    ''');
        }
        if (oldVersion < 6) {
          await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comic_id INTEGER NOT NULL UNIQUE,
         user_id INTEGER NOT NULL,
         UNIQUE(comic_id, user_id),
        created_at TEXT NOT NULL,
        FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE,
         FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE 
      )
    ''');

        }
          if (oldVersion < 7) {
  await db.execute('''CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    comic_id INTEGER NOT NULL,
    episode_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,                    
    message TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    dislike_count INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE,
    FOREIGN KEY (episode_id) REFERENCES episode(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  )''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS comment_replies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      comment_id INTEGER,
      message TEXT,
      created_at TEXT
    )
  ''');
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE,
  password TEXT
)''');
        }
 if (oldVersion < 8) {
    await db.execute('''
      ALTER TABLE comments ADD COLUMN user_id INTEGER
    ''');
    
    final users = await db.query('users', limit: 1);
    if (users.isNotEmpty) {
      final userId = users.first['id'];
      await db.execute('''
        UPDATE comments SET user_id = ? WHERE user_id IS NULL
      ''', [userId]);
    }
  }        await _seedIfEmpty(db);
      },
    );
  }

  static Future<void> _createAllTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS comics (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  cover_path TEXT NOT NULL
)

    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS favorites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      comic_id INTEGER NOT NULL UNIQUE,
          user_id INTEGER NOT NULL, 
      created_at TEXT NOT NULL,
                UNIQUE(comic_id, user_id),    

      FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE,
       FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE,
  password TEXT
)'''
    
  );
    await db.execute('''
      CREATE TABLE comic_detail (
        comic_id INTEGER PRIMARY KEY,
        author TEXT NOT NULL,
        genres TEXT NOT NULL,
        synopsis TEXT NOT NULL,
        FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE episode (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comic_id INTEGER NOT NULL,
        ep_no INTEGER NOT NULL,
        title TEXT NOT NULL,
        UNIQUE(comic_id, ep_no),
        FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE page (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        episode_id INTEGER NOT NULL,
        page_no INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        UNIQUE(episode_id, page_no),
        FOREIGN KEY (episode_id) REFERENCES episode(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    comic_id INTEGER NOT NULL,
    episode_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,                    
    message TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    dislike_count INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE,
    FOREIGN KEY (episode_id) REFERENCES episode(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  )''');
    await db.execute('''CREATE TABLE comment_replies (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  comment_id INTEGER,
  message TEXT,
  created_at TEXT
   ) ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS reading_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      comic_id INTEGER NOT NULL,
      episode_id INTEGER NOT NULL,
      page_no INTEGER NOT NULL DEFAULT 0,
       user_id INTEGER NOT NULL,
      last_read_at TEXT NOT NULL,
      UNIQUE(comic_id, episode_id, user_id),
      FOREIGN KEY (comic_id) REFERENCES comics(id) ON DELETE CASCADE,
      FOREIGN KEY (episode_id) REFERENCES episode(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  ''');

  }

  static Future<void> _seed(DatabaseExecutor db) async {
    await db.insert('comics', {
      'id': 1,
      'title': 'kaisen jujutsu',
      'cover_path': 'assets/comic/jjk/cover.jpg',
    });
    await db.insert('comics', {
      'id': 2,
      'title': 'gantz',
      'cover_path': 'assets/comic/gantz/cover.png',
    });
    await db.insert('comics', {
    'id': 3,
    'title': 'One Punch Man',
    'cover_path': 'assets/comic/opm/ep1/opm01.jpg', 
  });
   await db.insert('comic_detail', {
    'comic_id': 3,
    'author': 'ONE',
    'genres': 'Action, Comedy, Superhero',
    'synopsis': 'ไซตามะ ฮีโร่ที่แข็งแกร่งจนชนะทุกศัตรูด้วยหมัดเดียว',
  });

    await db.insert('comic_detail', {
      'comic_id': 1,
      'author': 'Author A',
      'genres': 'Action, Horror',
      'synopsis': 'เรื่องย่อของ Comic 1',
    });
    await db.insert('comic_detail', {
      'comic_id': 2,
      'author': 'Author A',
      'genres': 'Action, Horror',
      'synopsis': 'เรื่องย่อของ Comic 2',
    });
     
   
    final ep1Id = await db.insert('episode', {
      'comic_id': 1,
      'ep_no': 1,
      'title': 'Chapter 1',
    });
    final ep2Id = await db.insert('episode', {
      'comic_id': 1,
      'ep_no': 2,
      'title': 'Chapter 2',
    });
 final opmEp1 = await db.insert('episode', {
    'comic_id': 3,
    'ep_no': 1,
    'title': 'Chapter 1',
  });
    for (int i = 1; i <= 23; i++) {
    await db.insert('page', {
      'episode_id': opmEp1,
      'page_no': i,
      'image_path': 'assets/comic/opm/ep1/opm${i.toString().padLeft(2, '0')}.jpg',
    });
  }
    await db.insert('page', {
      'episode_id': ep1Id,
      'page_no': 1,
      'image_path': 'assets/comic/jjk/cover.jpg',
    });
    await db.insert('page', {
      'episode_id': ep1Id,
      'page_no': 2,
      'image_path': 'assets/comic/jjk/cover.jpg',
    });
    await db.insert('page', {
      'episode_id': ep1Id,
      'page_no': 3,
      'image_path': 'assets/comic/jjk/cover.jpg',
    });

    await db.insert('page', {
      'episode_id': ep2Id,
      'page_no': 1,
      'image_path': 'assets/comic/jjk/cover.jpg',
    });
  }

  static Future<void> _seedIfEmpty(Database db) async {
    final comicsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM comics'),
        ) ??
        0;

    final pageCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM page')) ??
        0;

    if (comicsCount == 0 || pageCount == 0) {
      await _seed(db);
    }
  }

  static Future<void> resetAndSeed() async {
    final db = await database;

    await db.transaction((txn) async {
    
      await txn.delete('page');
      await txn.delete('episode');
      await txn.delete('comic_detail');
      await txn.delete('comics');

      await _seed(txn); 
    });
  }
}
