import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileTransferServer {
  late HttpServer _server;
  final int port;
  String? _webPageContent;

  // Categorized file lists
  final List<String> _photos = [];
  final List<String> _videos = [];
  final List<String> _documents = [];
  final List<String> _otherFiles = [];

  FileTransferServer({this.port = 8080});

  Future<void> start() async {
    // Load HTML from assets
    try {
      _webPageContent = await rootBundle.loadString('assets/web/index.html');
    } catch (e) {
      print('Error loading HTML asset: $e');
      _webPageContent = '''
        <html><body>
          <h1>Error</h1>
          <p>Could not load web interface</p>
        </body></html>
      ''';
    }

    // Scan for available files when server starts
    await _scanAvailableFiles();

    final router = Router()
      ..get('/', _rootHandler)
      ..get('/files/photos', _listPhotosHandler)
      ..get('/files/videos', _listVideosHandler)
      ..get('/files/documents', _listDocumentsHandler)
      ..get('/files/others', _listOtherFilesHandler)
      ..get('/download/<filepath|.*>', _downloadFileHandler);

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router);

    _server = await io.serve(handler, InternetAddress.anyIPv4, port);
    print('Server running on ${_server.address}:${_server.port}');
  }

  Future<void> stop() async {
    await _server.close();
    print('Server stopped');
  }

  Future<void> _scanAvailableFiles() async {
    _photos.clear();
    _videos.clear();
    _documents.clear();
    _otherFiles.clear();

    // Get common media and download directories
    final List<Directory> targetDirs = [];

    try {
      // Get the external storage directory
      final externalStorage = await getExternalStorageDirectory();
      if (externalStorage != null) {
        final parentDir = externalStorage.parent.parent.parent;

        // Add standard media directories
        targetDirs.addAll([
          Directory('${parentDir.path}/DCIM'),
          Directory('${parentDir.path}/DCIM/Camera'),
          Directory('${parentDir.path}/Pictures'),
          Directory('${parentDir.path}/Download'),
          Directory('${parentDir.path}/Downloads'),
        ]);
      }

      // Also check standard paths directly
      targetDirs.addAll([
        Directory('/storage/emulated/0/DCIM'),
        Directory('/storage/emulated/0/DCIM/Camera'),
        Directory('/storage/emulated/0/Pictures'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Downloads'),
      ]);

      // Scan each target directory
      for (var dir in targetDirs) {
        if (await dir.exists()) {
          try {
            await _scanAndCategorizeDirectory(dir);
          } catch (e) {
            print('Error scanning ${dir.path}: $e');
          }
        }
      }

      // Sort files by name in each category
      _sortFilesByCategory();

    } catch (e) {
      print('Error scanning files: $e');
    }
  }

  Future<void> _scanAndCategorizeDirectory(Directory dir) async {
    try {
      final entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is File) {
          _categorizeFile(entity);
        } else if (entity is Directory) {
          await _scanAndCategorizeDirectory(entity);
        }
      }
    } catch (e) {
      print('Error scanning ${dir.path}: $e');
    }
  }

  void _categorizeFile(File file) {
    final ext = path.extension(file.path).toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv'];
    final docExtensions = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'];

    if (imageExtensions.contains(ext)) {
      _photos.add(file.path);
    } else if (videoExtensions.contains(ext)) {
      _videos.add(file.path);
    } else if (docExtensions.contains(ext)) {
      _documents.add(file.path);
    } else {
      _otherFiles.add(file.path);
    }
  }

  void _sortFilesByCategory() {
    _photos.sort((a, b) => path.basename(a).compareTo(path.basename(b)));
    _videos.sort((a, b) => path.basename(a).compareTo(path.basename(b)));
    _documents.sort((a, b) => path.basename(a).compareTo(path.basename(b)));
    _otherFiles.sort((a, b) => path.basename(a).compareTo(path.basename(b)));
  }

  Future<Response> _rootHandler(Request request) async {
    if (_webPageContent == null) {
      return Response.notFound('Web page not loaded');
    }
    return Response.ok(_webPageContent, headers: {'Content-Type': 'text/html'});
  }

  Future<Response> _listPhotosHandler(Request request) async {
    return _listFilesResponse(_photos);
  }

  Future<Response> _listVideosHandler(Request request) async {
    return _listFilesResponse(_videos);
  }

  Future<Response> _listDocumentsHandler(Request request) async {
    return _listFilesResponse(_documents);
  }

  Future<Response> _listOtherFilesHandler(Request request) async {
    return _listFilesResponse(_otherFiles);
  }

  Future<Response> _listFilesResponse(List<String> files) async {
    try {
      return Response.ok(
        files.join('\n'),
        headers: {'Content-Type': 'text/plain'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error listing files: $e');
    }
  }

  Future<Response> _downloadFileHandler(Request request, String filepath) async {
    try {
      final decodedPath = Uri.decodeFull(filepath);
      final file = File(decodedPath);

      if (await file.exists()) {
        final filename = path.basename(decodedPath);
        return Response.ok(
          file.openRead(),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': 'attachment; filename="$filename"',
            'Content-Length': (await file.length()).toString(),
          },
        );
      }
      return Response.notFound('File not found');
    } catch (e) {
      return Response.internalServerError(body: 'Error downloading file: $e');
    }
  }
}


// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_router/shelf_router.dart';
// import 'package:flutter/services.dart';
// import 'dart:io';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
//
// class FileTransferServer {
//   late HttpServer _server;
//   final int port;
//   String? _webPageContent;
//   List<String> _availableFiles = [];
//
//   FileTransferServer({this.port = 8080});
//
//   Future<void> start() async {
//     // Load HTML from assets
//     try {
//       _webPageContent = await rootBundle.loadString('assets/web/index.html');
//     } catch (e) {
//       print('Error loading HTML asset: $e');
//       _webPageContent = '''
//         <html><body>
//           <h1>Error</h1>
//           <p>Could not load web interface</p>
//         </body></html>
//       ''';
//     }
//
//     // Scan for available files when server starts
//     await _scanAvailableFiles();
//
//     final router = Router()
//       ..get('/', _rootHandler)
//       ..get('/files', _listFilesHandler)
//       ..get('/download/<filepath|.*>', _downloadFileHandler);
//
//     final handler = Pipeline()
//         .addMiddleware(logRequests())
//         .addHandler(router);
//
//     _server = await io.serve(handler, InternetAddress.anyIPv4, port);
//     print('Server running on ${_server.address}:${_server.port}');
//   }
//
//   Future<void> stop() async {
//     await _server.close();
//     print('Server stopped');
//   }
//
//   Future<void> _scanAvailableFiles() async {
//     _availableFiles.clear();
//
//     // Get common directories
//     final List<Directory> roots = [];
//
//     try {
//       // Internal storage
//       final appDir = await getApplicationDocumentsDirectory();
//       roots.add(Directory(appDir.parent.parent.parent.path));
//
//       // External storage (SD card)
//       final externalDirs = await getExternalStorageDirectories();
//       if (externalDirs != null && externalDirs.isNotEmpty) {
//         for (var dir in externalDirs) {
//           roots.add(Directory(dir.parent.parent.parent.path));
//         }
//       }
//
//       // Add standard directories
//       roots.addAll([
//         Directory('/storage/emulated/0'), // Main storage
//         Directory('/storage'), // All storage devices
//         Directory('/sdcard'), // Common symlink to storage
//       ]);
//
//       // Scan each root directory
//       for (var root in roots) {
//         if (await root.exists()) {
//           try {
//             await _scanDirectory(root, _availableFiles, maxDepth: 2);
//           } catch (e) {
//             print('Error scanning ${root.path}: $e');
//           }
//         }
//       }
//
//       // Sort files by name
//       _availableFiles.sort((a, b) => path.basename(a).toLowerCase().compareTo(path.basename(b).toLowerCase()));
//
//     } catch (e) {
//       print('Error scanning files: $e');
//     }
//   }
//
//   Future<void> _scanDirectory(Directory dir, List<String> files, {int maxDepth = 2, int currentDepth = 0}) async {
//     if (currentDepth > maxDepth) return;
//
//     try {
//       final entities = await dir.list().toList();
//       for (var entity in entities) {
//         if (entity is File) {
//           files.add(entity.path);
//         } else if (entity is Directory) {
//           await _scanDirectory(entity, files, maxDepth: maxDepth, currentDepth: currentDepth + 1);
//         }
//       }
//     } catch (e) {
//       print('Error scanning ${dir.path}: $e');
//     }
//   }
//
//   Future<Response> _rootHandler(Request request) async {
//     if (_webPageContent == null) {
//       return Response.notFound('Web page not loaded');
//     }
//     return Response.ok(_webPageContent, headers: {'Content-Type': 'text/html'});
//   }
//
//   Future<Response> _listFilesHandler(Request request) async {
//     try {
//       // Return the list of available files as JSON
//       return Response.ok(
//         _availableFiles.join('\n'),
//         headers: {'Content-Type': 'text/plain'},
//       );
//     } catch (e) {
//       return Response.internalServerError(body: 'Error listing files: $e');
//     }
//   }
//
//   Future<Response> _downloadFileHandler(Request request, String filepath) async {
//     try {
//       final decodedPath = Uri.decodeFull(filepath);
//       final file = File(decodedPath);
//
//       if (await file.exists()) {
//         final filename = path.basename(decodedPath);
//         return Response.ok(
//           file.openRead(),
//           headers: {
//             'Content-Type': 'application/octet-stream',
//             'Content-Disposition': 'attachment; filename="$filename"',
//             'Content-Length': (await file.length()).toString(),
//           },
//         );
//       }
//       return Response.notFound('File not found');
//     } catch (e) {
//       return Response.internalServerError(body: 'Error downloading file: $e');
//     }
//   }
// }



// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_router/shelf_router.dart';
// import 'package:shelf_static/shelf_static.dart';
// import 'package:flutter/services.dart';
// import 'dart:io';
//
// class FileTransferServer {
//   late HttpServer _server;
//   final int port;
//   String? _webPageContent;
//
//   FileTransferServer({this.port = 8080});
//
//   Future<void> start() async {
//     // Load HTML from assets
//     try {
//       _webPageContent = await rootBundle.loadString('assets/web/index.html');
//     } catch (e) {
//       print('Error loading HTML asset: $e');
//       _webPageContent = '''
//         <html><body>
//           <h1>Error</h1>
//           <p>Could not load web interface</p>
//         </body></html>
//       ''';
//     }
//
//     final router = Router()
//       ..get('/', _rootHandler)
//       ..get('/files', _listFilesHandler)
//       ..get('/download/<filepath|.*>', _downloadFileHandler);
//
//     final handler = Pipeline()
//         .addMiddleware(logRequests())
//         .addHandler(router);
//
//     _server = await io.serve(handler, InternetAddress.anyIPv4, port);
//     print('Server running on ${_server.address}:${_server.port}');
//   }
//
//   Future<void> stop() async {
//     await _server.close();
//     print('Server stopped');
//   }
//
//   Future<Response> _rootHandler(Request request) async {
//     if (_webPageContent == null) {
//       return Response.notFound('Web page not loaded');
//     }
//     return Response.ok(_webPageContent, headers: {'Content-Type': 'text/html'});
//   }
//
//   Future<Response> _listFilesHandler(Request request) async {
//     try {
//       // This endpoint is just for the web interface
//       // The actual files are listed from the Flutter app
//       return Response.ok('');
//     } catch (e) {
//       return Response.internalServerError(body: 'Error listing files: $e');
//     }
//   }
//
//   Future<Response> _downloadFileHandler(Request request, String filepath) async {
//     try {
//       final file = File(Uri.decodeFull(filepath));
//       if (await file.exists()) {
//         return Response.ok(
//           await file.readAsBytes(),
//           headers: {
//             'Content-Type': 'application/octet-stream',
//             'Content-Disposition': 'attachment; filename="${file.path.split('/').last}"'
//           },
//         );
//       }
//       return Response.notFound('File not found');
//     } catch (e) {
//       return Response.internalServerError(body: 'Error downloading file: $e');
//     }
//   }
// }

// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_router/shelf_router.dart';
// import 'package:shelf_static/shelf_static.dart';
// import 'package:flutter/services.dart';
// import 'dart:io';
//
// class FileTransferServer {
//   late HttpServer _server;
//   final int port;
//
//   FileTransferServer({this.port = 8080});
//
//   Future<void> start() async {
//     final router = Router()
//       ..get('/', _rootHandler)
//       ..get('/files', _listFilesHandler)
//       ..get('/download/<filepath|.*>', _downloadFileHandler);
//
//     final handler = Pipeline()
//         .addMiddleware(logRequests())
//         .addHandler(router);
//
//     _server = await io.serve(handler, InternetAddress.anyIPv4, port);
//     print('Server running on ${_server.address}:${_server.port}');
//   }
//
//   Future<void> stop() async {
//     await _server.close();
//     print('Server stopped');
//   }
//
//   Future<Response> _rootHandler(Request request) async {
//     final html = '''
//       <html>
//         <head>
//           <title>File Share Server</title>
//           <style>
//             body { font-family: Arial, sans-serif; margin: 20px; }
//             h1 { color: #333; }
//             ul { list-style-type: none; padding: 0; }
//             li { margin: 5px 0; }
//             a { color: #0066cc; text-decoration: none; }
//             a:hover { text-decoration: underline; }
//           </style>
//         </head>
//         <body>
//           <h1>File Share Server</h1>
//           <p>Available files:</p>
//           <ul id="fileList"></ul>
//           <script>
//             fetch('/files')
//               .then(response => response.text())
//               .then(data => {
//                 const files = data.split('\\n');
//                 const list = document.getElementById('fileList');
//                 files.forEach(file => {
//                   if (file.trim()) {
//                     const li = document.createElement('li');
//                     const a = document.createElement('a');
//                     a.href = '/download/' + encodeURIComponent(file);
//                     a.textContent = file.split('/').pop() + ' (' + file + ')';
//                     li.appendChild(a);
//                     list.appendChild(li);
//                   }
//                 });
//               });
//           </script>
//         </body>
//       </html>
//     ''';
//     return Response.ok(html, headers: {'Content-Type': 'text/html'});
//   }
//
//   Future<Response> _listFilesHandler(Request request) async {
//     try {
//       // This endpoint is just for the web interface
//       // The actual files are listed from the Flutter app
//       return Response.ok('');
//     } catch (e) {
//       return Response.internalServerError(body: 'Error listing files: $e');
//     }
//   }
//
//   Future<Response> _downloadFileHandler(Request request, String filepath) async {
//     try {
//       final file = File(Uri.decodeFull(filepath));
//       if (await file.exists()) {
//         return Response.ok(
//           await file.readAsBytes(),
//           headers: {
//             'Content-Type': 'application/octet-stream',
//             'Content-Disposition': 'attachment; filename="${file.path.split('/').last}"'
//           },
//         );
//       }
//       return Response.notFound('File not found');
//     } catch (e) {
//       return Response.internalServerError(body: 'Error downloading file: $e');
//     }
//   }
// }

// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_router/shelf_router.dart';
// import 'package:shelf_static/shelf_static.dart';
// import 'package:flutter/services.dart';  // Added for asset access
// import 'dart:io';
//
// class FileTransferServer {
//   late HttpServer _server;
//   final String sharedDirectory;
//   final int port;
//   String? _webPageContent;
//
//   FileTransferServer({required this.sharedDirectory, this.port = 8080});
//
//   Future<void> start() async {
//     // Create directory if it doesn't exist
//     await Directory(sharedDirectory).create(recursive: true);
//
//     // Load HTML from assets
//     _webPageContent = await rootBundle.loadString('assets/web/index.html');
//
//     final router = Router()
//       ..get('/', _rootHandler)
//       ..get('/files', _listFilesHandler)
//       ..get('/download/<filename>', _downloadFileHandler);
//
//     final handler = Pipeline()
//         .addMiddleware(logRequests())
//         .addHandler(router);
//
//     _server = await io.serve(handler, InternetAddress.anyIPv4, port);
//     print('Server running on ${_server.address}:${_server.port}');
//   }
//
//   Future<void> stop() async {
//     await _server.close();
//     print('Server stopped');
//   }
//
//   Future<Response> _rootHandler(Request request) async {
//     if (_webPageContent == null) {
//       return Response.notFound('Web page not loaded');
//     }
//     return Response.ok(_webPageContent, headers: {'Content-Type': 'text/html'});
//   }
//
//   Future<Response> _listFilesHandler(Request request) async {
//     final files = await _getFileList();
//     return Response.ok(files.join('\n'));
//   }
//
//   Future<Response> _downloadFileHandler(Request request, String filename) async {
//     final file = File('$sharedDirectory/$filename');
//     if (await file.exists()) {
//       return Response.ok(
//         await file.readAsBytes(),
//         headers: {'Content-Type': 'application/octet-stream'},
//       );
//     }
//     return Response.notFound('File not found');
//   }
//
//   Future<List<String>> _getFileList() async {
//     final dir = Directory(sharedDirectory);
//     return await dir.list()
//         .where((entity) => entity is File)
//         .map((entity) => (entity as File).uri.pathSegments.last)
//         .toList();
//   }
// }


// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_router/shelf_router.dart';
// import 'dart:io';
//
// class FileTransferServer {
//   late HttpServer _server;
//   final String sharedDirectory;
//   final int port;
//
//   FileTransferServer({required this.sharedDirectory, this.port = 8080});
//
//   Future<void> start() async {
//     // Create directory if it doesn't exist
//     await Directory(sharedDirectory).create(recursive: true);
//
//     final router = Router()
//       ..get('/files', _listFilesHandler)
//       ..get('/download/<filename>', _downloadFileHandler);
//
//     final handler = Pipeline()
//         .addMiddleware(logRequests())
//         .addHandler(router);
//
//     _server = await io.serve(handler, InternetAddress.anyIPv4, port);
//     print('Server running on ${_server.address}:${_server.port}');
//   }
//
//   Future<void> stop() async {
//     await _server.close();
//     print('Server stopped');
//   }
//
//   Future<Response> _listFilesHandler(Request request) async {
//     final dir = Directory(sharedDirectory);
//     final files = await dir.list()
//         .where((entity) => entity is File)
//         .map((entity) => (entity as File).uri.pathSegments.last)
//         .toList();
//
//     return Response.ok(files.join('\n'));
//   }
//
//   Future<Response> _downloadFileHandler(Request request, String filename) async {
//     final file = File('$sharedDirectory/$filename');
//     if (await file.exists()) {
//       return Response.ok(
//         await file.readAsBytes(),
//         headers: {'Content-Type': 'application/octet-stream'},
//       );
//     }
//     return Response.notFound('File not found');
//   }
// }