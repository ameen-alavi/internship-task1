import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

enum DeviceScreenType { mobile, tablet, desktop }

class ResponsiveHelper {
  ResponsiveHelper._();

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppDimensions.mobileBreakpoint) {
      return DeviceScreenType.mobile;
    } else if (width < AppDimensions.tabletBreakpoint) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppDimensions.mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppDimensions.mobileBreakpoint &&
        width < AppDimensions.tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppDimensions.tabletBreakpoint;

  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceScreenType.mobile:
        return mobile;
      case DeviceScreenType.tablet:
        return tablet ?? desktop;
      case DeviceScreenType.desktop:
        return desktop;
    }
  }
}

class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context) desktop;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppDimensions.mobileBreakpoint) {
          return mobile(context);
        } else if (constraints.maxWidth < AppDimensions.tabletBreakpoint) {
          return (tablet ?? desktop)(context);
        } else {
          return desktop(context);
        }
      },
    );
  }
}
