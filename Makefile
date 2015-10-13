# Configuration
AI_NAME = JAMI
AI_VERSION = 3
FILES = COPYING *.nut
# End of configuration

NAME_VERSION = $(AI_NAME).$(AI_VERSION)
TAR_NAME = $(NAME_VERSION).tar


all: bundle

bundle: Makefile $(FILES)
	@mkdir "$(NAME_VERSION)"
	@cp $(FILES) "$(NAME_VERSION)"
	@tar -cf "$(TAR_NAME)" "$(NAME_VERSION)"
	@rm -r "$(NAME_VERSION)"
