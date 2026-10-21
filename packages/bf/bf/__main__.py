import argparse

from bf.claude import manage_sessions


def main():
    parser = argparse.ArgumentParser(prog="bf")
    subparsers = parser.add_subparsers(required=True)

    subparser = subparsers.add_parser(
        "claude", help="browse, resume, rename and delete Claude Code sessions"
    )
    subparser.set_defaults(func=manage_sessions)

    args = parser.parse_args()
    args.func()


if __name__ == "__main__":
    main()
