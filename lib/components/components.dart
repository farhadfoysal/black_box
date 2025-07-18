library component;

import 'dart:math' as math;

import 'package:badges/badges.dart' as b;
import 'package:black_box/cores/cores.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:black_box/model/course/video_course.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:transparent_image/transparent_image.dart';

import '../model/course/course_model.dart';

part 'cards/learned_card.dart';
part 'cards/new_course_card.dart';
part 'cards/video_course_card.dart';
part 'cards/video_learning_card.dart';
part 'common/app_buttom_bar.dart';
part 'common/app_pull_refresh.dart';
part 'common/dot_container.dart';
part 'common/sub_header.dart';
part 'common/user_info.dart';
