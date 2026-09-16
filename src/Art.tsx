import React from "react";
import Svg, { Circle, Ellipse, Path, Rect, G, Line } from "react-native-svg";
export function Person({
  color = "#5c79d9",
  size = 48,
}: {
  color?: string;
  size?: number;
}) {
  return (
    <Svg width={size} height={size} viewBox="0 0 48 48">
      <Ellipse cx="24" cy="43" rx="14" ry="4" fill="#31452c" opacity=".17" />
      <Path d="M17 34v9m14-9v9" stroke="#614e45" strokeWidth="6" />
      <Rect x="13" y="22" width="22" height="17" rx="8" fill={color} />
      <Circle cx="24" cy="15" r="11" fill="#e9b68d" />
      <Path d="M13 15Q9 0 25 3Q39 2 35 17L30 10 15 13" fill="#6b4833" />
      <Circle cx="20" cy="16" r="1.2" />
      <Circle cx="28" cy="16" r="1.2" />
      <Path d="M21 21q3 2 6 0" stroke="#ab684b" strokeWidth="1.5" fill="none" />
    </Svg>
  );
}
export function ItemArt({ kind, size = 64 }: { kind: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 64 64">
      <Ellipse cx="32" cy="54" rx="23" ry="5" fill="#2e5132" opacity=".12" />
      {kind === "egg" ? (
        <>
          <Path
            d="M32 6C17 6 10 33 13 43C18 61 48 58 51 42C54 28 42 6 32 6"
            fill="#fff4d9"
            stroke="#d9bc88"
            strokeWidth="2"
          />
          <Ellipse cx="25" cy="25" rx="5" ry="9" fill="#fff" opacity=".8" />
        </>
      ) : kind === "chick" ? (
        <>
          <Circle cx="30" cy="36" r="21" fill="#f5cf55" />
          <Circle cx="37" cy="21" r="15" fill="#ffe479" />
          <Circle cx="41" cy="18" r="2.5" fill="#4a4232" />
          <Path d="M50 22l10 4-10 4" fill="#e59343" />
          <Path d="M17 34q12-5 14 10" fill="#e8b64b" />
          <Path d="M24 55v6m13-6v6" stroke="#c58141" strokeWidth="3" />
        </>
      ) : (
        <>
          <Rect
            x="7"
            y="14"
            width="50"
            height="39"
            rx="8"
            fill="#e7bc60"
            stroke="#b38938"
            strokeWidth="2"
          />
          {[21, 28, 35, 42].map((y) => (
            <Line
              key={y}
              x1="12"
              x2="52"
              y1={y}
              y2={y}
              stroke="#fce19b"
              strokeWidth="2"
            />
          ))}
          <Path d="M21 14v39m23-39v39" stroke="#b6803b" strokeWidth="5" />
        </>
      )}
    </Svg>
  );
}
export function FarmArt({ upgrade }: { upgrade: number }) {
  return (
    <Svg width={960} height={720} viewBox="0 0 960 720">
      <Rect width="960" height="720" fill="#a5c989" />
      {Array.from({ length: 300 }, (_, i) => (
        <G key={i}>
          <Rect
            x={(i % 20) * 48}
            y={Math.floor(i / 20) * 48}
            width="48"
            height="48"
            fill={(i + Math.floor(i / 20)) % 2 ? "#abcE91" : "#a4c88a"}
          />
          {i % 3 === 0 && (
            <Path
              d={`M${(i % 20) * 48 + 15} ${Math.floor(i / 20) * 48 + 32}l-2-5m2 5 4-4`}
              stroke="#7fac70"
              strokeWidth="2"
              opacity=".5"
            />
          )}
        </G>
      ))}
      <Path
        d="M0 454H960M458 0V720M263 264V454M698 250V454"
        stroke="#c4ad77"
        strokeWidth="62"
      />
      <Path
        d="M0 452H960M458 0V720M263 264V454M698 250V454"
        stroke="#e4cf9f"
        strokeWidth="53"
      />
      {Array.from({ length: 26 }, (_, i) => (
        <G key={i} transform={`translate(${i * 38},12)`}>
          <Rect x="0" y="0" width="7" height="39" rx="3" fill="#f4e4c6" />
          <Rect x="0" y="9" width="38" height="6" fill="#f4e4c6" />
          <Rect x="0" y="26" width="38" height="5" fill="#f4e4c6" />
        </G>
      ))}
      <G transform="translate(94,94)">
        <Ellipse
          cx="100"
          cy="141"
          rx="110"
          ry="19"
          fill="#628550"
          opacity=".3"
        />
        <Rect
          x="5"
          y="30"
          width="185"
          height="108"
          rx="5"
          fill={upgrade ? "#e5b375" : "#bf925f"}
        />
        <Path d="M-12 42L97-8 207 42Z" fill={upgrade ? "#d77758" : "#9d765f"} />
        <Path d="M-12 42h218" stroke="#975139" strokeWidth="8" />
        <Rect x="73" y="77" width="48" height="61" rx="20" fill="#675b43" />
        <Rect x="25" y="66" width="29" height="30" rx="3" fill="#b5deeb" />
        <Path d="M40 66v30m-15-15h29" stroke="#fff0d4" strokeWidth="4" />
        {upgrade > 0 && (
          <G>
            <Rect x="143" y="65" width="30" height="27" rx="3" fill="#b5deeb" />
            <Path d="M150 118l10-20 10 20" fill="#81a859" />
            <Circle cx="161" cy="99" r="6" fill="#fff0b1" />
          </G>
        )}
      </G>
      <G transform="translate(576,94)">
        <Ellipse
          cx="120"
          cy="146"
          rx="133"
          ry="18"
          fill="#628550"
          opacity=".3"
        />
        <Rect
          x="5"
          y="32"
          width="229"
          height="111"
          rx="4"
          fill={upgrade > 1 ? "#d9816c" : "#b28b70"}
        />
        <Path d="M-10 41L55-6H189L248 41Z" fill="#716879" />
        <Rect x="81" y="63" width="75" height="80" fill="#745e4c" />
        <Path d="M83 67l70 74m0-74-70 74" stroke="#eac59d" strokeWidth="6" />
        <Rect x="25" y="62" width="32" height="33" fill="#aed9db" />
        <Rect x="180" y="62" width="32" height="33" fill="#aed9db" />
      </G>
      <G transform="translate(576,480)">
        <Rect
          width="192"
          height="144"
          rx="18"
          fill={upgrade > 2 ? "#c6d99c" : "#bdcb96"}
        />
        {[0, 48, 96, 144, 185].map((x) => (
          <G key={x}>
            <Rect x={x} width="7" height="140" fill="#f5e1b4" />
          </G>
        ))}
        <Path d="M0 12h192M0 128h192" stroke="#eee0bd" strokeWidth="9" />
      </G>
      {[
        [55, 90],
        [870, 80],
        [890, 550],
        [65, 570],
        [815, 645],
        [190, 625],
        [780, 310],
      ].map(([x, y], i) => (
        <G key={i} transform={`translate(${x},${y})`}>
          <Ellipse
            cx="0"
            cy="25"
            rx="34"
            ry="12"
            fill="#628550"
            opacity=".25"
          />
          <Rect x="-6" y="-12" width="12" height="40" fill="#9b7654" />
          <Circle cy="-22" r="33" fill="#689c68" />
          <Circle cx="-14" cy="-29" r="21" fill="#80b178" />
          <Circle cx="14" cy="-37" r="24" fill="#85b779" />
        </G>
      ))}
      <G transform="translate(90,350)">
        {Array.from({ length: 12 }, (_, i) => (
          <G
            key={i}
            transform={`translate(${(i % 6) * 25},${Math.floor(i / 6) * 27})`}
          >
            <Ellipse rx="10" ry="5" fill="#998456" />
            <Path
              d="M0 0q-13-20-5-17Q0-16 0 0Q1-26 8-19Q13-9 0 0"
              fill="#568b50"
            />
          </G>
        ))}
      </G>
    </Svg>
  );
}
