part of component;

class VideoCourseCard extends StatefulWidget {
  final CourseModel item;
  final VoidCallback onPressed;

  const VideoCourseCard({
    super.key,
    required this.item,
    required this.onPressed,
  });

  @override
  State<VideoCourseCard> createState() => _VideoCourseCardState();
}

class _VideoCourseCardState extends State<VideoCourseCard> {
  Future<String?>? _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = fetchUserNameByUserId(widget.item.userId ?? "");
  }

  Future<String?> fetchUserNameByUserId(String userId) async {
    try {
      final DatabaseReference userRef =
          FirebaseDatabase.instance.ref("users/$userId");

      final DatabaseEvent event = await userRef.once();

      if (event.snapshot.exists) {
        final Map userMap = event.snapshot.value as Map;
        return userMap['uname'] ?? "Unknown";
      } else {
        print("No user found with ID: $userId");
        return null;
      }
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[300]!,
                blurRadius: 3,
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200.0,
                width: context.screenWidth,
                child: CachedNetworkImage(
                  imageUrl: widget.item.courseImage ?? "",
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/background.jpg',
                    fit: BoxFit.cover,
                  ),
                  imageBuilder: (context, assetProvider) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(radius)),
                      child: FadeInImage(
                        placeholder: MemoryImage(kTransparentImage),
                        image: assetProvider,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(17.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.courseName!.overflow,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: p20.bold,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Flexible(
                            child: widget.item.userId == null
                                ? const Text(
                                    "Unknown User",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  )
                                : FutureBuilder<String?>(
                                    future: fetchUserNameByUserId(
                                        widget.item.userId!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text(
                                          "Loading...",
                                          style: TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        );
                                      } else if (snapshot.hasError) {
                                        return const Text(
                                          "Unknown User",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.redAccent),
                                        );
                                      } else if (snapshot.hasData) {
                                        return InkWell(
                                          onTap: () {
                                            // ✅ define what to do when user name is tapped
                                            print("User clicked: ${snapshot.data}");
                                            // Or navigate somewhere, or show a dialog
                                          },
                                          child: Text(
                                            snapshot.data ?? "Unknown",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      } else {
                                        return const Text(
                                          "Unknown",
                                          style: TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        );
                                      }
                                    },
                                  )),
                        const DotContainer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(widget.item.level ?? '', style: p15.grey),
                        ),
                        const DotContainer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            "${widget.item.totalTime} ${widget.item.totalVideo! > 1 ? 'Lessons' : 'Lesson'}",
                            style: p15.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class VideoCourseCard extends StatelessWidget {
//   final CourseModel item;
//   final VoidCallback onPressed;
//
//   const VideoCourseCard({
//     super.key,
//     required this.item,
//     required this.onPressed,
//   });
//
//
//   Future<String?> fetchUserName(String userId) async {
//     final ref = FirebaseDatabase.instance.ref("users/$userId");
//     final snapshot = await ref.once();
//
//     if (snapshot.snapshot.exists) {
//       final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
//       return data['name']?.toString();
//     }
//     return null;
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     const radius = 20.0;
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: InkWell(
//         onTap: () => onPressed(),
//         borderRadius: BorderRadius.circular(radius),
//         child: Ink(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(radius),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.grey[300]!,
//                 blurRadius: 3,
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               SizedBox(
//                 height: 200.0,
//                 width: context.screenWidth,
//                 child: CachedNetworkImage(
//                   imageUrl: item.courseImage??"",
//                   placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
//                   errorWidget: (context, url, error) => Image.asset(
//                     'assets/background.jpg',
//                     fit: BoxFit.cover,
//                   ),
//                   imageBuilder: (context, assetProvider) {
//                     return ClipRRect(
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
//                       child: FadeInImage(
//                         placeholder: MemoryImage(kTransparentImage),
//                         image: assetProvider,
//                         fit: BoxFit.cover,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(17.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       item.courseName!.overflow,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: p20.bold,
//                     ),
//                     const SizedBox(height: 15),
//                     Row(
//                       children: [
//                         Flexible(
//                           child: UserInfo(
//                             onPressed: () {
//
//                             },
//                             expanded: false,
//                             title: item.userId,
//                             avatarURL: item.userId,
//                           ),
//                         ),
//                         const DotContainer(),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 2),
//                           child: Text(item.level!, style: p15.grey),
//                         ),
//                         const DotContainer(),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 2),
//                           child: Text(
//                             "${item.totalTime} ${item.totalVideo! > 1 ? 'Lessons' : 'Lesson'}",
//                             style: p15.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
