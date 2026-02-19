# G902 - Appendix 02 ~ Vim `.vimrc` configuration

- [The default Vim configuration can feel insufficient](#the-default-vim-configuration-can-feel-insufficient)
- [Practical Vim configuration](#practical-vim-configuration)
- [References](#references)
- [Navigation](#navigation)

## The default Vim configuration can feel insufficient

Vim has a rather bare bones default configuration, which it does not feel that convenient when editing texts through a shell terminal. This appendix offers you an example of a Vim configuration that enables some quality-of-life features that may improve your text-editing experience.

## Practical Vim configuration

A very practical `.vimrc` configuration for Vim is the following:

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

" Disable autocomment of next line (bothersome when pasting texts with comments)
autocmd FileType * set formatoptions-=cro
~~~

Just create a `.vimrc` file, with the lines above, in any user's $HOME folder. Then copy the all lines above in the `.vimrc` file. Of course, do not hesitate to adjust these parameters to your personal preferences (in particular the indentation and tabs configuration).

## References

- [StackOverflow. Tab key == 4 spaces and auto-indent after curly braces in Vim](https://stackoverflow.com/questions/234564/tab-key-4-spaces-and-auto-indent-after-curly-braces-in-vim)

## Navigation

[<< Previous (**G901. Appendix 01**)](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G903. Appendix 03**) >>](G903%20-%20Appendix%2003%20~%20Customization%20of%20the%20motd%20file.md)
