# upg updates everything this machine knows how to update.
# Mirrors the bash version in ~/.bashrc.d/21-update.
function upg
    # Take the sudo prompt once, up front, instead of halfway through.
    sudo true; or return 1

    function __upg_run --no-scope-shadowing
        type -q $argv[1]; or return 0
        printf "\n>> %s\n\n" "$argv[2..-1]"
        $argv[2..-1]
    end

    __upg_run pacman sudo pacman -Syu

    __upg_run apt sudo apt update
    __upg_run apt sudo apt full-upgrade -y
    __upg_run apt-get sudo apt-get autoremove -y --purge
    __upg_run apt-get sudo apt-get clean -y

    __upg_run dnf sudo dnf upgrade -y

    __upg_run flatpak flatpak update
    __upg_run snap sudo snap refresh
    __upg_run brew brew update
    __upg_run brew brew upgrade

    __upg_run mise mise upgrade

    functions -e __upg_run
end
