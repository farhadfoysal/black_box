part of component;

class VideoCourseCard extends StatelessWidget {
  final CourseModel item;
  final VoidCallback onPressed;

  const VideoCourseCard({
    super.key,
    required this.item,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 20.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => onPressed(),
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
                  imageUrl: item.courseImage??"",
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/background.jpg',
                    fit: BoxFit.cover,
                  ),
                  imageBuilder: (context, assetProvider) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
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
                      item.courseName!.overflow,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: p20.bold,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Flexible(
                          child: UserInfo(
                            onPressed: () {},
                            expanded: false,
                            title: item.userId,
                            avatarURL: item.userId,
                          ),
                        ),
                        const DotContainer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(item.level!, style: p15.grey),
                        ),
                        const DotContainer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            "${item.totalTime} ${item.totalVideo! > 1 ? 'Lessons' : 'Lesson'}",
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