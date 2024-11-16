// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

interface IChronicle {
    /**
     * @notice Returns the oracle's current value.
     * @dev Reverts if no value set.
     * @return value The oracle's current value.
     */
    function read() external view returns (uint256 value);

    /**
     * @notice Returns the oracle's current value and its age.
     * @dev Reverts if no value set.
     * @return value The oracle's current value using 18 decimals places.
     * @return age The value's age as a Unix Timestamp .
     *
     */
    function readWithAge() external view returns (uint256 value, uint256 age);
}

interface ISelfKisser {
    /// @notice Kisses caller on oracle `oracle`.
    function selfKiss(address oracle) external;

    function kiss(address oracle) external;

}
