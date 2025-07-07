part of component;

class NewCourseCard extends StatefulWidget {
  CourseModel courseModel;
  final String imageUrl;
  final String title;
  final int countPlays;
  final Function onPressed;

  NewCourseCard({
    super.key,
    required this.courseModel,
    required this.imageUrl,
    required this.title,
    required this.countPlays,
    required this.onPressed,
  });


  @override
  State<StatefulWidget> createState() => NewCourseCardState();
}

class NewCourseCardState extends State<NewCourseCard>{
  @override
  Widget build(BuildContext context) {
    const TextStyle textInVideoStyle = TextStyle(color: Colors.white, fontSize: 16);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: GestureDetector(
        onTap: () => widget.onPressed(),
        child: Stack(
          children: [
            SizedBox(
              height: 300,
              width: 205,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/background.jpg',
                  fit: BoxFit.cover,
                ),
                imageBuilder: (context, assetProvider) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FadeInImage(
                      placeholder: MemoryImage(kTransparentImage),
                      image: assetProvider,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 170,
              bottom: 0,
              right: 0,
              left: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2).copyWith(top: 1, bottom: 4),
                  child: Text('new', style: p15.white),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 45,
              child: SizedBox(
                width: 180,
                child: Text(
                  widget.title.overflow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: p17.white,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(widget.countPlays.toAbbreviatedString(), style: textInVideoStyle),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}