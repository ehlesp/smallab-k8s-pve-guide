# G902 - Appendix 02 ~ Vim `.vimrc` configuration

A very practical `.vimrc` configuration for VIM is the following.

~~~vim
" Configuration for tabs, always 4 spaces (like in the Python standard)
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab

" Show line numbers
set nu

~~~

Just create a `.vimrc` file, with the lines above, in any user's $HOME folder.

## References

- [Tab key == 4 spaces and auto-indent after curly braces in Vim](https://stackoverflow.com/questions/234564/tab-key-4-spaces-and-auto-indent-after-curly-braces-in-vim)

## Navigation

[<< Previous (**G901. Appendix 01**)](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G903. Appendix 03**) >>](G903%20-%20Appendix%2003%20~%20Customization%20of%20the%20motd%20file.md)
